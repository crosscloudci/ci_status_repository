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
                                                   where: skp.source_id == ^monitor.source_pipeline_id) |> List.first
    {:ok, monitor, source_key_project, source_key_pipeline}
  end

  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    last_checked
    {:ok, monitor, source_key_project, source_key_pipeline} = migrate_source_key_monitor(source_key_project_monitor_id)
    
    target_source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.project_build_pipeline_id) |> List.first
    
    Logger.info fn ->
      "GitlabMonitor: source_key_project : #{inspect(source_key_project)}"
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

    # TODO if no build job status and cloud job status records for passed project, create/default to running or N/A

    # TODO put polling in caller i.e. controller
    #
    # TODO populate ref_monitor
    upsert_ref_monitor(source_key_project.new_id,source_key_pipeline.new_id)
    
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

  # projects, clouds, pipleines, and pipeline jobs should be recently migrated before calling build status 
  def build_status(pipeline_id) do
     # determine the build status
     #    i.e. get the build job (name = container)
     #    if exists, dashboard badge status status = build job status
     #    if doesn't exist, dashboard badge status = running
    container = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                                          where: pj.pipeline_id == ^pipeline_id)
                |> Enum.find(fn(x) -> x.name =~ "container" end) 

    Logger.info fn ->
      "build_status: #{inspect(container)}"
    end

    if container && (container.status == "success" || container.status == "failed") do
      container.status
    else
      "running"
    end
  end

  def cloud_status(monitor_job_list, child_pipeline, _cloud, internal_pipeline_id) do

    Logger.info fn ->
      "cloud_status monitored_job_list: #{inspect(monitor_job_list)}"
    end
    # get all the jobs for the internal pipeline
    monitored_jobs = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                              where: pj.pipeline_id == ^internal_pipeline_id)
    Logger.info fn ->
      "cloud_status monitored_jobs: #{inspect(monitored_jobs)}"
    end

    # loop through the jobs list in the order of precedence
      # monitor_job_list e.g. ["e2e", "App-Deploy"]
    # create status string e.g. "failure"
    # If any job in the status jobs list has a status of failed, return failed
    # else if any job in the list has a status of running, return running
    # else 
    #    if not child pipeline
    #      if all jobs are a success, return success
    status = monitor_job_list 
             |> Enum.reduce_while("initial", fn(monitor_name, acc) ->
                job = Enum.find(monitored_jobs, fn(x) -> x.name =~ monitor_name end) 
                Logger.info fn ->
                  "monitored job string: #{inspect(monitor_name)}. job: #{inspect(job)}"
                end
                cond do
                  job && (job.status =~ "failed" || job.status =~ "cancelled") ->
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
                    # can only go to a success status from initial or success status
                    if (child_pipeline == false && (acc =~ "success" || acc =~ "initial")) do
                      acc = "success" 
                    end
                    {:cont, acc}
                  true ->
                    Logger.error fn ->
                      "unhandled job status: #{inspect(job)}.  #{inspect(monitor_name)} not found"
                    end
                    {:cont, acc}
                end 
             end) 
  end

  def compile_url(pipeline_id) do
     # determine the build status
     #    i.e. get the build job (name = compile)
     #    if exists, dashboard badge status status = build job status
     #    if doesn't exist, dashboard badge status = running
     project = Repo.all(from projects in CncfDashboardApi.Projects, 
                                          left_join: pipelines in assoc(projects, :pipelines),     
                                          where: pipelines.id == ^pipeline_id) 
                                          |> List.first
    Logger.info fn ->
      "compile url project: #{inspect(project)}"
    end

    compile = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                                          where: pj.pipeline_id == ^pipeline_id)
                |> Enum.find(fn(x) -> x.name =~ "compile" end) 

    Logger.info fn ->
      "compile job: #{inspect(compile)}"
    end

    if compile do
      Logger.info fn ->
        "source key pipeline jobs, should be only 1: #{inspect(Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelineJobs, where: skpj.new_id == ^compile.id))}"
      end
      source_key_pipeline_jobs = Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelineJobs, 
                                                   where: skpj.new_id == ^compile.id) |> List.first
      Logger.info fn ->
        "compile local pipeline_id: #{pipeline_id} *first* source key: #{inspect(source_key_pipeline_jobs)}"
      end
      # e.g.   https://gitlab.dev.cncf.ci/coredns/coredns/-/jobs/31525
      "#{project.web_url}/-/jobs/#{source_key_pipeline_jobs.source_id}"
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
          "ref_monitor found update: #{inspect(rm_found)}"
        end
      :not_found ->
        {:ok, rm_record} = Repo.insert(changeset) 
        Logger.info fn ->
          "ref_monitor not found insert: #{inspect(rm_found)}"
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

    changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(dbs_record, 
               %{ref: target_pl.ref,
                 status: build_status(target_pm.pipeline_id),
                 ref_monitor_id: rm_record.id,
                 url: compile_url(target_pm.pipeline_id),
                 order: 1 # build badge always 1 
               })

    Logger.info fn ->
      "upsert_ref_monitor DashboardBadgeStatus.changeset : #{inspect(changeset)}"
    end

    case dbs_found do
      :found ->
        {_, dbs_record} = Repo.update(changeset) 
      :not_found ->
        {_, dbs_record} = Repo.insert(changeset) 
    end
     
    #  # TODO loop through all clouds
    cloud_list = Repo.all(from cd1 in CncfDashboardApi.Clouds, 
                                           where: cd1.active == true,
                                           order_by: [cd1.order]) 
    Logger.info fn ->
      "cloud_list : #{inspect(cloud_list)}"
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
        cc_status = CncfDashboardApi.GitlabMonitor.cloud_status(monitored_job_list("cross-cloud"), cross_cloud_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_cloud_pipeline_monitor.pipeline_id)
      end

      Logger.info fn ->
        "cross_project_pipeline_monitor: #{inspect(cross_project_pipeline_monitor)}"
      end
      if cross_project_pipeline_monitor do
        cp_status = CncfDashboardApi.GitlabMonitor.cloud_status(monitored_job_list("cross-project"), cross_project_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_project_pipeline_monitor.pipeline_id)
      end
 
      cond do
        (cp_status && cp_status != "") -> 
          status = cp_status 
        (cc_status && cc_status != "") ->
          status = cc_status 
        true ->
          status = "N/A"
      end
      
      # # TODO if all status == success or failed, running = false
      # if (status == "success") do
      #   {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      #     project_id: source_key_project.new_id,
      #     release_type: monitor.pipeline_release_type} 
      #     |> find_by([:pipeline_id, :project_id, :release_type])
      #
      #     changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, 
      #                                                      %{ running: false,
      #                                                      })
      #
      #   case pm_found do
      #     :found ->
      #       {_, pm_record} = Repo.update(changeset) 
      #     :not_found ->
      #       {_, pm_record} = Repo.insert(changeset) 
      #   end
      #   Logger.info fn ->
      #     "GitlabMonitor: upsert pipeline monitor: #{inspect(pm_record)}"
      #   end
      # end

      Logger.info fn ->
        "cp_status: #{inspect(cp_status)}"
      end
      Logger.info fn ->
        "cc_status: #{inspect(cc_status)}"
      end
      Logger.info fn ->
        "status: #{inspect(status)}"
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

     # TODO determine cloud url 
      changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(dbs_record, 
                                                                  %{ref: target_pl.ref,
                                                                    status: status,
                                                                    ref_monitor_id: rm_record.id,
                                                                    url: "http://example.com",
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
            "dbs not found : #{inspect(dbs_record)}"
          end
      end
    end)
     #
     # TODO determine cloud status
     #    determine cloud_id of the job (or set of jobs) status
     #    set order to the cloud order
     #
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
