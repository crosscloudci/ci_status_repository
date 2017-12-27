require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor do
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo


  def last_checked do
    yml = System.get_env("GITLAB_CI_YML")
    {d_found, d_record} = %CncfDashboardApi.Dashboard{gitlab_ci_yml: yml } |> find_by([:gitlab_ci_yml])
    changeset = CncfDashboardApi.Dashboard.changeset(d_record, %{last_check: Ecto.DateTime.utc, gitlab_ci_yml: yml, })
    case d_found do
      :found ->
        # {_, d_record} = Repo.update!(changeset) 
         Repo.update!(changeset) 
      :not_found ->
        # {_, d_record} = Repo.insert!(changeset) 
         Repo.insert!(changeset) 
    end
  end

 @doc """
  Get the source key models for the source key monitor, the project, and the pipeline 
  based on `source_key_project_monitor_id`.

  Source keys map the keys in gitlab to the keys in our database.

  A migration from gitlab must have occured before calling this function in order to get 
  valid data 

  Returns `{:ok, monitor, source_key_project, source_key_pipeline}`
  """
  def source_models(source_key_project_monitor_id) do
    monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                                        where: skpm.id == ^source_key_project_monitor_id) |> List.first
    source_key_project = Repo.all(from skp in CncfDashboardApi.SourceKeyProjects, 
                                                   where: skp.source_id == ^monitor.source_project_id) |> List.first
    source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.source_pipeline_id) |> List.first
    {:ok, monitor, source_key_project, source_key_pipeline}
  end

 @doc """
  Retrieve the pipeline monitor record based on the `source_key_project_monitor_id`.
  The pipeline monitor record maintains the local keys for monitored pipelines and
  is keyed based on project_id,  pipeline_id and release_type

  Returns `{found, record}`.
  """
  def pipeline_monitor(source_key_project_monitor_id) do
    {:ok, monitor, source_key_project, source_key_pipeline} = source_models(source_key_project_monitor_id)

    case is_deploy_pipeline_type(source_key_project.new_id) do
      true -> pipeline_type = "deploy"
      _ -> pipeline_type = "build"
    end

    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      pipeline_type: pipeline_type,
      release_type: monitor.pipeline_release_type} 
      |> find_by([:pipeline_id, :project_id, :pipeline_type, :release_type])
  end

  def target_project_exist?(project_name, source_pipeline_id) do
    {p_found, p_record} = %CncfDashboardApi.Projects{name: project_name } |> find_by([:name])
    {pl_found, pl_record} = %CncfDashboardApi.SourceKeyPipelines{source_id: source_pipeline_id } |> find_by([:source_id])
    if (p_found == :not_found || pl_found == :not_found) do
      false
    else
      true
    end
  end

  def migrate_source_key_monitor(source_key_project_monitor_id) do
    # migrate clouds
    CncfDashboardApi.GitlabMigrations.upsert_clouds()
    # need to upsert all the projects to keep the dashboard listing all current projects
    CncfDashboardApi.GitlabMigrations.upsert_projects()
    monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                       where: skpm.id == ^source_key_project_monitor_id) |> List.first
    Logger.info fn ->
      "GitlabMonitor: source_key_project_monitor : #{inspect(monitor)}"
    end

    # make sure the immediate project is upserted
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_project(monitor.source_project_id) 

    # upsert yml project properties
    CncfDashboardApi.GitlabMigrations.upsert_yml_projects()

    # get the local project id
    source_key_project = Repo.all(from skp in CncfDashboardApi.SourceKeyProjects, 
                                  where: skp.source_id == ^monitor.source_project_id) |> List.first

                                  # migrate pipeline 
    {:ok, upsert_count, pipeline_map} = CncfDashboardApi.GitlabMigrations.upsert_pipeline(monitor.source_project_id, monitor.source_pipeline_id) 

    # get the local pipeline
    source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                   where: skp.source_id == ^monitor.source_pipeline_id) 
                                   |> List.first

    # migrate missing internal id, if it doesn't exist
    unless target_project_exist?(monitor.target_project_name, monitor.project_build_pipeline_id) do
      CncfDashboardApi.GitlabMigrations.upsert_missing_target_project_pipeline( monitor.target_project_name, monitor.project_build_pipeline_id)
    end
                                   
    {:ok, monitor, source_key_project, source_key_pipeline}
  end

  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    last_checked
    {:ok, monitor, source_key_project, source_key_pipeline} = migrate_source_key_monitor(source_key_project_monitor_id)
    
    target_source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.project_build_pipeline_id) |> List.first
    
    Logger.info fn ->
      "GitlabMonitor: monitor : #{inspect(monitor)}"
    end

    Logger.info fn ->
      "GitlabMonitor: source_key_project : #{inspect(source_key_project)}"
    end

    Logger.info fn ->
      "GitlabMonitor: target_source_key_pipeline : #{inspect(target_source_key_pipeline)}"
    end
    # determine pipeline type
    case is_deploy_pipeline_type(source_key_project.new_id) do
      true -> pipeline_type = "deploy"
      _ -> pipeline_type = "build"
    end

    alternate_release = if (monitor.pipeline_release_type == "stable"), do: "head", else: "stable"

    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      release_type: alternate_release} 
      |> find_by([:pipeline_id, :project_id, :release_type])

      case pm_found do
        :found -> raise "You may not monitor the same project and pipeline for two different branches"
        _ -> :ok
      end

      # Insert only if pipeline, project, and release type do not exist
      # else update
      {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
        project_id: source_key_project.new_id,
        pipeline_type: pipeline_type,
        release_type: monitor.pipeline_release_type} 
        |> find_by([:pipeline_id, :project_id, :pipeline_type,:release_type])

        changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, 
                                                               %{project_id: source_key_project.new_id,
                                                                 pipeline_id: source_key_pipeline.new_id,
                                                                 running: true,
                                                                 release_type: monitor.pipeline_release_type,
                                                                 pipeline_type: pipeline_type ,
                                                                 cloud: monitor.cloud,
                                                                 child_pipeline: monitor.child_pipeline,
                                                                 target_project_name: monitor.target_project_name,
                                                                 internal_build_pipeline_id: target_source_key_pipeline.new_id
                                                               })

    case pm_found do
      :found ->
        {_, pm_record} = Repo.update(changeset) 
        Logger.info fn ->
          "found: update pipeline monitor: #{inspect(pm_record)}"
        end
      :not_found ->
        {_, pm_record} = Repo.insert(changeset) 
        Logger.info fn ->
          "not found: insert pipeline monitor: #{inspect(pm_record)}"
        end
    end

    # migrate all jobs for the pipeline 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(monitor.source_project_id |> String.to_integer, 
                                                           monitor.source_pipeline_id |> String.to_integer)

    upsert_ref_monitor(source_key_project.new_id,source_key_pipeline.new_id)
    # TODO if no build job status and cloud job status records for passed project, create/default to running or N/A

    # TODO put polling in caller i.e. controller
    #
    # TODO populate ref_monitor
    
    # Call dashboard channel
    CncfDashboardApi.Endpoint.broadcast! "dashboard:*", "new_cross_cloud_call", %{reply: dashboard_response} 

    Logger.info fn ->
      "GitlabMonitor: Broadcasted json"
    end

    # TODO update last updated

  end

  def dashboard_response do
    yml = System.get_env("GITLAB_CI_YML")
    {d_found, d_record} = %CncfDashboardApi.Dashboard{gitlab_ci_yml: yml } |> find_by([:gitlab_ci_yml])
    cloud_list = Repo.all(from cd1 in CncfDashboardApi.Clouds, 
                          where: cd1.active == true,
                          order_by: [cd1.order]) 
    projects = Repo.all(from projects in CncfDashboardApi.Projects,      
                        left_join: ref_monitors in assoc(projects, :ref_monitors),
                        left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                        left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                        where: projects.active == true,
                        order_by: [projects.order, ref_monitors.order, dashboard_badge_statuses.order], 
                        preload: [ref_monitors: 
                                  {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                    dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                  }] )

    with_cloud = %{"dashboard" => d_record, "clouds" => cloud_list, "projects" => projects} 
    response = CncfDashboardApi.DashboardView.render("index.json", dashboard: with_cloud)
  end

  # project name is either cross-cloud (cross-cloud handles the deploy pipelines)
  # or other (a build pipeline)
  def is_deploy_pipeline_type(project_id) do
    project = Repo.all(from skp in CncfDashboardApi.Projects, 
                       where: skp.id == ^project_id) |> List.first
    Logger.info fn ->
      "is_deploy_pipeline_type project: #{inspect(project)}"
    end
    if (project.name =~ "cross-cloud" || project.name =~ "cross-project") do
      true
    else
      false
    end

  end

 @doc """
  Gets a list of migrated jobs based on based on `pipeline_id` and `job_names`.

  job_names is a list of strings denoting the job name

  A migration from gitlab must have occured before calling this function in order to get 
  valid jobs 

  Returns `[%job1, %job2]`
  """
  def monitored_jobs(job_names, pipeline_id) do
    Logger.info fn ->
      "monitored_job_list job_names: #{inspect(job_names)}"
    end
    # get all the jobs for the internal pipeline
    jobs = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                              where: pj.pipeline_id == ^pipeline_id,
                              where: pj.name in ^job_names)
    Logger.info fn ->
      "monitored_job_list monitored_jobs: #{inspect(jobs)}"
    end

    # sort by job_names
    job_names
    |> Enum.reduce([], fn(job_name, acc) ->
      job = Enum.find(jobs, fn(x) -> x.name =~ job_name end) 
        if job do
          [job | acc]
        else
          acc
        end
    end)
    |> Enum.reverse
  end

  def badge_status_by_pipeline_id(monitor_job_list, child_pipeline, _cloud, internal_pipeline_id) do

    Logger.info fn ->
      "badge_status_by_pipeline_id monitored_job_list: #{inspect(monitor_job_list)}"
    end

    monitored_jobs = monitored_jobs(monitor_job_list, internal_pipeline_id)

    Logger.info fn ->
      "badge_status_by_pipeline_id monitored_jobs: #{inspect(monitored_jobs)}"
    end

    # loop through the jobs list in the order of precedence
    # monitor_job_list e.g. ["e2e", "App-Deploy"]
    # create status string e.g. "failure"
    # If any job in the status jobs list has a status of failed, return failed
    # else if any job in the list has a status of running, return running
    # else 
    #    if not child pipeline
    #      if all jobs are a success, return success
    status = monitored_jobs 
             |> Enum.reduce_while("initial", fn(job, acc) ->
               Logger.info fn ->
                 "badge_status_by_pipeline_id monitored job: #{inspect(job)}"
               end
               cond do
                 job && (job.status =~ "failed" || job.status =~ "canceled") ->
                   acc = "failed"  
                   {:halt, acc}
                 job && (job.status =~ "running" || job.status =~ "created") ->
                   # can only go to a running status from initial, running, or success status
                   if (acc =~ "running" || acc =~ "initial" || acc =~ "success") do
                     acc = "running" 
                   end
                   {:cont, acc}
                 job && job.status =~ "success" ->
                   # The Backend Dashboard will NOT set the badge status to success when a 
                   # child -- it's ignored for a child 
                   # can only go to a success status from initial, running, or success status
                   if (child_pipeline == false && (acc =~ "success" || acc =~ "initial" || 
                     acc =~ "running")) do
                     acc = "success" 
                   end
                   {:cont, acc}
                 true ->
                 Logger.error fn ->
                   "unhandled job status: #{inspect(job)}  not handled"
                 end
                 {:cont, acc}
               end 
             end) 
  end

  def badge_url(monitor_job_list, child_pipeline, internal_pipeline_id) do
     project = Repo.all(from projects in CncfDashboardApi.Projects, 
                                          left_join: pipelines in assoc(projects, :pipelines),     
                                          where: pipelines.id == ^internal_pipeline_id) 
                                          |> List.first
    Logger.info fn ->
      "deploy url project: #{inspect(project)}"
    end

    monitored_jobs = monitored_jobs(monitor_job_list, internal_pipeline_id)
    status_job = monitored_jobs 
             |> Enum.reduce_while(%{:status => "initial", :job => :nojob}, fn(job, acc) ->
               Logger.info fn ->
                 "monitored job: #{inspect(job)}"
               end
                cond do
                  job && (job.status =~ "failed" || job.status =~ "canceled") ->
                    acc = %{status: "failed", job: job}
                    {:halt, acc}
                  job && (job.status =~ "running" || job.status =~ "created") ->
                    # can only go to a running status from initial, running, or success status
                    if (acc.status =~ "running" || acc.status =~ "initial" || acc.status =~ "success") do
                      acc = %{status: "running" , job: job}
                    end
                    {:cont, acc}
                  job && job.status =~ "success" ->
                    if (child_pipeline == false && (acc.status =~ "success" || acc.status =~ "initial")) do
                      acc = %{status: "success", job: job} 
                    end
                    {:cont, acc}
                  true ->
                 Logger.error fn ->
                   "unhandled job status: #{inspect(job)}  not handled"
                 end
                    {:cont, acc}
                end 
             end) 

    Logger.info fn ->
      "status_job: #{inspect(status_job)}"
    end
    Logger.info fn ->
      "status_job.job: #{inspect(status_job.job)}"
    end

    if status_job.job != :nojob do
      Logger.info fn ->
        "status_job.job != :nojob"
      end
      source_key_pipeline_jobs = Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelineJobs, where: skpj.new_id == ^status_job.job.id) |> List.first
      if source_key_pipeline_jobs do
        "#{project.web_url}/-/jobs/#{source_key_pipeline_jobs.source_id}"
      else
        ""
      end
    end
  end

  # project, pipeline, and pipeline jobs should be migrated before
  # calling upsert_ref_monitor
  # 1. source_key_project_monitor is called from a http post
  # 2. pipeline_monitor is created/updated during the http_post
  # 3. upsert_ref_monitor is called to set up the dashboard
  def upsert_ref_monitor(project_id, pipeline_id) do

    Logger.info fn ->
      "upsert_ref_monitor project id: #{project_id} pipeline_id: #{pipeline_id}"
    end


    # get project
    project = Repo.all(from p in CncfDashboardApi.Projects, 
                       where: p.id == ^project_id) |> List.first
                       # get pipeline
    pipeline = Repo.all(from p in CncfDashboardApi.Pipelines, 
                        where: p.id == ^pipeline_id) |> List.first
                        # get pipeline jobs
    pipeline_jobs = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                             where: pj.pipeline_id == ^pipeline_id)

    {pm_found, pipeline_monitor} = %CncfDashboardApi.PipelineMonitor{pipeline_id: pipeline.id, 
      project_id: project_id} |> find_by([:pipeline_id, :project_id])

    Logger.info fn ->
      " upsert_ref_monitor pipeline_monitor: #{inspect(pipeline_monitor)}"
    end

    # initialize the dashboard on build pipeline only
    if pipeline_monitor.pipeline_type == "build" do
      initialize_ref_monitor(project_id)
    end

    #  get all clouds
    clouds = Repo.all(from c in CncfDashboardApi.Clouds)

    if pipeline.release_type == "stable" do
      pipeline_order = 1
    else
      pipeline_order = 2
    end

    # if never given a release status for the pipeline, raise an error

    # if  deploy pipline, use the target project for the refmonitor
    Logger.info fn ->
      " upsert_ref_monitor pipeline_monitor.internal_build_pipeline_id: #{inspect(pipeline_monitor.internal_build_pipeline_id)}"
    end
    Logger.info fn ->
      " upsert_ref_monitor all build pipeline_monitors: #{inspect(Repo.all(CncfDashboardApi.PipelineMonitor) )}"
    end
    if pipeline_monitor.pipeline_type == "deploy" do
      target_pm = Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                           where: pm.pipeline_id == ^pipeline_monitor.internal_build_pipeline_id, 
                           where: pm.pipeline_type == "build") |> List.first
                           target_pl = Repo.all(from pm in CncfDashboardApi.Pipelines, 
                                                where: pm.id == ^pipeline_monitor.internal_build_pipeline_id ) |> List.first
      Logger.info fn ->
        " upsert_ref_monitor target_pm: #{inspect(target_pm)}"
      end
    else
      target_pm = pipeline_monitor
      target_pl = pipeline
    end

    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
      release_type: pipeline_monitor.release_type} 
      |> find_by([:project_id, :release_type])

    changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
                                                      %{ref: target_pl.ref,
                                                        status: target_pl.status,
                                                        sha: target_pl.sha,
                                                        release_type: target_pm.release_type,
                                                        project_id: target_pm.project_id,
                                                        pipeline_id: target_pl.id,
                                                        order: pipeline_order
                                                      })

    case rm_found do
      :found ->
        {:ok, rm_record} = Repo.update(changeset) 
      Logger.info fn ->
        "ref_monitor found update: #{inspect(rm_record)}"
      end
      :not_found ->
        {:ok, rm_record} = Repo.insert(changeset) 
      Logger.error fn ->
        "ref_monitor not found insert (should never happen): #{inspect(rm_record)}"
      end
    end

    # build dashboard_badget_status
    # get the dashboard badge for the build job
    #   i.e. get the dashboard badge with order = 1

    #
    # upsert the build status badge based on ref_monitor and order (always 1)
    Logger.info fn ->
      "upsert_ref_monitor rm_record.id : #{inspect(rm_record)}"
    end
    {dbs_found, dbs_record} = %CncfDashboardApi.DashboardBadgeStatus{ref_monitor_id: rm_record.id, order: 1} 
                              |> find_by([:ref_monitor_id, :order])

    job_names = monitored_job_list("project")
    changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(dbs_record, 
                                                                %{ref: target_pl.ref,
                                                                  status: badge_status_by_pipeline_id(job_names, false, "", target_pm.pipeline_id),
                                                                  ref_monitor_id: rm_record.id,
                                                                  url: badge_url(job_names, false, target_pm.pipeline_id),
                                                                  order: 1 # build badge always 1 
                                                                })

    Logger.info fn ->
      "upsert_ref_monitor DashboardBadgeStatus.changeset : #{inspect(changeset)}"
    end

    case dbs_found do
      :found ->
        {_, dbs_record} = Repo.update(changeset) 
      Logger.info fn ->
        "dashboard status found update: #{inspect(dbs_record)}"
      end
      :not_found ->
        {_, dbs_record} = Repo.insert(changeset) 
      Logger.error fn ->
        "dashboard status not found insert (should never happen): #{inspect(dbs_record)}"
      end
    end

    # TODO get all the pipelines for the current working_project
    # if pipeline_type = "build" then the project_id is a target project
    # if pipeline_type = "deploy" then this is a pipeline project 
    if pipeline_monitor.pipeline_type == "build" do
      deploy_pipeline_monitors = Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                                          where: pm.internal_build_pipeline_id == ^pipeline_monitor.pipeline_id,
                                          where: pm.pipeline_type == "deploy") 
    else
      deploy_pipeline_monitors = Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                                          where: pm.internal_build_pipeline_id == ^pipeline_monitor.internal_build_pipeline_id,
                                          where: pm.pipeline_type == "deploy") 
    end

    Logger.info fn ->
      "deploy_pipeline_monitors : #{inspect(deploy_pipeline_monitors)}"
    end

    #TODO put order on pipelines in yml
    #TODO until then cross-cloud always comes before cross-project
    #
    Logger.info fn ->
      "cross_cloud ad cross_project:"
    end

    cc = Repo.all(from p in CncfDashboardApi.Projects, where: p.name == "cross-cloud") |> List.last
    Logger.info fn ->
      "cross_cloud project: #{inspect(cc)}"
    end

    cp = Repo.all(from p in CncfDashboardApi.Projects, where: p.name == "cross-project") |> List.first
    Logger.info fn ->
      "cross_project project: #{inspect(cp)}"
    end

    #  # TODO loop through all clouds
    posted_clouds = deploy_pipeline_monitors |> Enum.uniq_by(fn(x) -> x.cloud end) |> Enum.reduce([], fn(x,acc)-> [x.cloud | acc] end)
    Logger.info fn ->
      "posted_clouds : #{inspect(posted_clouds)}"
    end

    cloud_list = Repo.all(from cd1 in CncfDashboardApi.Clouds, where: cd1.active == true, where: cd1.cloud_name in ^posted_clouds, order_by: [cd1.order]) 
    Logger.info fn ->
      "filtered cloud_list : #{inspect(cloud_list)}"
    end

    # TODO only loop through clouds that have deploy pipeline monitors
    Enum.map(cloud_list, fn(cloud) ->
      Logger.info fn ->
        "cloud_name: #{inspect(cloud.cloud_name)}"
      end
      cross_cloud_pipeline_monitor = Enum.find(deploy_pipeline_monitors, fn(x) ->
        x.project_id == cc.id && x.cloud == cloud.cloud_name
      end)
      cross_project_pipeline_monitor = Enum.find(deploy_pipeline_monitors, fn(x) ->
        x.project_id == cp.id && x.cloud == cloud.cloud_name
      end)

      Logger.info fn ->
        "cross_cloud_pipeline_monitor: #{inspect(cross_cloud_pipeline_monitor)}"
      end
      if cross_cloud_pipeline_monitor do
        job_names = monitored_job_list("cross-cloud")
        cc_status = badge_status_by_pipeline_id(job_names, cross_cloud_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_cloud_pipeline_monitor.pipeline_id)
        cc_deploy_url = badge_url(job_names, cross_cloud_pipeline_monitor.child_pipeline, cross_cloud_pipeline_monitor.pipeline_id)
      end

      Logger.info fn ->
        "cross_project_pipeline_monitor: #{inspect(cross_project_pipeline_monitor)}"
      end
      if cross_project_pipeline_monitor do
        job_names = monitored_job_list("cross-project")
        cp_status = badge_status_by_pipeline_id(job_names, cross_project_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_project_pipeline_monitor.pipeline_id)
        cp_deploy_url = badge_url(job_names, cross_project_pipeline_monitor.child_pipeline, cross_project_pipeline_monitor.pipeline_id)
      end

      cond do
        (cp_status && cp_status != "" && cc_status != "failed") -> 
          status = cp_status 
          deploy_url = cp_deploy_url
        (cc_status && cc_status != "") ->
          status = cc_status 
          deploy_url = cc_deploy_url
        true ->
          status = "N/A"
          deploy_url = "" 
      end

      Logger.info fn ->
        "cp_status: #{inspect(cp_status)}"
      end
      Logger.info fn ->
        "cc_status: #{inspect(cc_status)}"
      end
      Logger.info fn ->
        "status: #{inspect(status)}"
      end
      Logger.info fn ->
        "deploy_url: #{inspect(deploy_url)}"
      end
      # Logger.info fn ->
      #   "all dashboards status: #{inspect(Repo.all(
      #     from dbs in CncfDashboardApi.DashboardBadgeStatus,
      #     where: dbs.ref_monitor_id == ^rm_record.id))}"
      # end

      cloud_order = cloud.order + 1
      Logger.info fn ->
        "cloud : #{inspect(cloud)}"
      end
      {dbs_found, dbs_record} = %CncfDashboardApi.DashboardBadgeStatus{ref_monitor_id: rm_record.id, order: (cloud_order)} |> find_by([:ref_monitor_id, :order])

      changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(dbs_record, 
                                                                  %{ref: target_pl.ref,
                                                                    status: status,
                                                                    ref_monitor_id: rm_record.id,
                                                                    url: deploy_url,
                                                                    cloud_id: cloud.id,
                                                                    order: cloud_order # build badge always 1 
                                                                  })

      Logger.info fn ->
        "upsert_ref_monitor cloud status DashboardBadgeStatus.changeset : #{inspect(changeset)}"
      end

      case dbs_found do
        :found ->
          {_, dbs_record} = Repo.update(changeset) 
        Logger.info fn ->
          "dbs_found : #{inspect(dbs_record)}"
        end
        :not_found ->
          {_, dbs_record} = Repo.insert(changeset) 
        Logger.info fn ->
          "dbs not found (should never happen) : #{inspect(dbs_record)}"
        end
      end
    end)
  end

  def monitored_job_list(project_name) do
    cloud_list = CncfDashboardApi.YmlReader.GitlabCi.gitlab_pipeline_config()
    pipeline_config = Enum.find(cloud_list, fn(x) -> x["pipeline_name"] == project_name end) 
    pipeline_config["status_jobs"]
  end

  # projects and clouds must be migrated before calling initialize_ref_monitor
  def initialize_ref_monitor(project_id) do
    Logger.info fn ->
      "initialize_ref_monitor: initializing"
    end

    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "stable"} 
                            |> find_by([:project_id, :release_type])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "stable", 1) # stable order is always 1
      _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'stable'"
      end
    end

    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "head"} 
                            |> find_by([:project_id, :release_type])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "head", 2) # head order is always 2
      _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'head'"
      end
    end

  end

  def new_n_a_ref_monitor(project_id, release_type, ref_order) do
    # insert a stable ref_monitor
    Logger.info fn -> "new_n_a_ref_monitor" end
    changeset = CncfDashboardApi.RefMonitor.changeset(%CncfDashboardApi.RefMonitor{}, 
                                                      %{ref: "N/A",
                                                        status: "N/A",
                                                        sha: "N/A",
                                                        release_type: release_type,
                                                        project_id: project_id,
                                                        order: ref_order 
                                                      })
    {_, rm_record} = Repo.insert(changeset) 
    #      insert a databoard_badge for build status with status of N/A for the new ref_monitor
    changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(%CncfDashboardApi.DashboardBadgeStatus{}, 
                                                                %{ref: "N/A",
                                                                  status: "N/A",
                                                                  ref_monitor_id: rm_record.id,
                                                                  order: 1 # build badge always 1 
                                                                })
    {_, dbs_record} = Repo.insert(changeset) 
    #  get all clouds
    Repo.all(from c in CncfDashboardApi.Clouds, where: c.active == true,
             order_by: :order)
             # insert one dashboard_badge for each cloud with status of N/A for the new ref_monitor
             |> Enum.map(fn(x) -> 
               Logger.info fn ->
                 "new dashboard badge status cloud: #{inspect(x)}"
               end
               cloud_order = x.order + 1 # clouds start with 2 wrt badge status
               changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(%CncfDashboardApi.DashboardBadgeStatus{}, 
                                                                           %{ref: "N/A",
                                                                             status: "N/A",
                                                                             cloud_id: x.id,
                                                                             ref_monitor_id: rm_record.id,
                                                                             order: cloud_order })
                                                                             {_, dbs_record} = Repo.insert(changeset) 
               Logger.info fn ->
                 "new initialized dashboard badge status: #{inspect(dbs_record)}"
               end

             end) 
  end

end
