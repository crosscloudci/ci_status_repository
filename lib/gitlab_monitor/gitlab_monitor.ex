require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor do
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo

 @doc """
  Updates the dashboard based on `source_key_project_monitor_id`.

  Returns `:ok`
  """
  def update_dashboard(source_key_project_monitor_id) do
    CncfDashboardApi.GitlabMonitor.Dashboard.last_checked()
    migrate_source_key_monitor(source_key_project_monitor_id)
    |> upsert_pipeline_monitor_info
    |> upsert_ref_monitor
    CncfDashboardApi.GitlabMonitor.Dashboard.broadcast()
    :ok
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

 @doc """
  Checks if the target project has been migrated based on `project_name` and `source_pipeline_id`.

  Returns `boolean`.
  """
  def target_project_exist?(project_name, source_pipeline_id) do
    {p_found, p_record} = %CncfDashboardApi.Projects{name: project_name } |> find_by([:name])
    {pl_found, pl_record} = %CncfDashboardApi.SourceKeyPipelines{source_id: source_pipeline_id } |> find_by([:source_id])
    Logger.info fn ->
      "GitlabMonitor: target_project_exist? project, source_key_pipeline : #{inspect(p_record)}, #{inspect(pl_record)}"
    end
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
      "migrate_source_key_monitor: source_key_project_monitor : #{inspect(monitor)}"
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
      Logger.info fn ->
        "migrate_source_key_monitor: target_project did not exist"
      end
      CncfDashboardApi.GitlabMigrations.upsert_missing_target_project_pipeline( monitor.target_project_name, monitor.project_build_pipeline_id)
    end

    target_source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.project_build_pipeline_id) |> List.first

    Logger.info fn ->
      "migrate_source_key_monitor: monitor : #{inspect(monitor)}"
    end

    Logger.info fn ->
      "migrate_source_key_monitor: source_key_project : #{inspect(source_key_project)}"
    end

    Logger.info fn ->
      "migrate_source_key_monitor: target_source_key_pipeline : #{inspect(target_source_key_pipeline)}"
    end
                                   
    {:ok, {monitor, source_key_project, source_key_pipeline, source_key_project_monitor_id, target_source_key_pipeline}}
  end

 @doc """
  Migrates the source key pipeline_monitor into the internal pipeline monitor based on `{%monitor, %source_key_project, %source_key_pipeline, source_key_project_monitor_id}`.

  Returns `[%SourceKeyProjects, %SourceKeyPipelines]`
  """
  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    update_dashboard(source_key_project_monitor_id)
    # {:ok, source_key_project_info} = migrate_source_key_monitor(source_key_project_monitor_id)
    # upsert_pipeline_monitor_info(source_key_project_info)
  end

  def upsert_pipeline_monitor_info({:ok, source_key_project_info}) do
    upsert_pipeline_monitor_info(source_key_project_info)
  end

 @doc """
  Migrates the source key pipeline_monitor into the internal pipeline monitor based on `source_key_project_monitor_id`.

  Returns `[%SourceKeyProjects, %SourceKeyPipelines]`
  """
  def upsert_pipeline_monitor_info({monitor, source_key_project, source_key_pipeline, source_key_project_monitor_id, target_source_key_pipeline} = source_key_project_info) do

    CncfDashboardApi.GitlabMonitor.Dashboard.last_checked()

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
    
    # CncfDashboardApi.GitlabMonitor.Dashboard.broadcast()

    project_pipeline_info = project_pipeline_info(source_key_project.new_id, source_key_pipeline.new_id)
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
 Gets all project and pipeline information based on the internal
 `project_id` and  `pipeline_id`.

  project, pipeline, and pipeline jobs should be migrated before
    calling project_pipeline_info 

  Returns `{:ok, %Projects, %Pipelines, [%PipelineJobs], %PipelineMonitor]}`
  """
  def project_pipeline_info(project_id, pipeline_id) do
    Logger.info fn ->
      "project_pipeline_info project id: #{project_id} pipeline_id: #{pipeline_id}"
    end
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
      "project_pipeline_info pipeline_monitor: #{inspect(pipeline_monitor)}"
    end

    {:ok, project, pipeline, pipeline_jobs, pipeline_monitor}
  end



 @doc """
  Selects the target pipeline info based on `{%PipelineMonitor, %Pipeline}`.

  target pipeline is the current (passed in) pipeline and pipeline monitor
  if the pipeline type is `deploy`

  target pipeline is based on the internal_build_pipeline_id 
  if the pipeline type is `build`

  Returns `{%PipelineMonitor, %Pipelines}`
  """
 def target_pipeline_info(pipeline_monitor, pipeline) do
    if pipeline_monitor.pipeline_type == "deploy" do
      target_pm = Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                           where: pm.pipeline_id == ^pipeline_monitor.internal_build_pipeline_id, 
                           where: pm.pipeline_type == "build") 
                           |> List.first()
      target_pl = Repo.all(from pm in CncfDashboardApi.Pipelines, 
                           where: pm.id == ^pipeline_monitor.internal_build_pipeline_id ) |> List.first

      if is_nil(target_pm) do
        Logger.error fn ->
          "Legacy dependency.  A deploy call with no build calls has been found for: #{inspect(pipeline_monitor)}"
        end
        raise "There should be no deploy pipelines that do not have a corresponding build pipeline 
        Must be a legacy call.  This deploy pipeline call is probably for a dependency that no 
        longer exists in the db"
        # target_pm = pipeline_monitor
        # target_pl = pipeline
      end
      Logger.info fn ->
        " upsert_ref_monitor deploy target_pm: #{inspect(target_pm)}"
      end
    else
      Logger.info fn ->
        " upsert_ref_monitor build target_pm: #{inspect(pipeline_monitor)}"
      end
      target_pm = pipeline_monitor
      target_pl = pipeline
    end
    {target_pm, target_pl}
 end

 @doc """
  Updates one ref monitor based on `project_id` and  `pipeline_id`.

  project, pipeline, and pipeline jobs should be migrated before
    calling upsert_ref_monitor

  1. source_key_project_monitor is called from a http post
  2. pipeline_monitor is created/updated during the http_post
  3. upsert_ref_monitor is called to set up the dashboard

  Returns `[%DashboardBadgeStatus]`
  """
  def upsert_ref_monitor(project_id, pipeline_id) do
    Logger.info fn ->
      "upsert_ref_monitor project id: #{project_id} pipeline_id: #{pipeline_id}"
    end
    project_pipeline_info = project_pipeline_info(project_id, pipeline_id)
    upsert_ref_monitor(project_pipeline_info)
  end

  def upsert_ref_monitor({:ok, project, pipeline, pipeline_jobs, pipeline_monitor} = project_pipeline_monitor) do
    upsert_ref_monitor({project, pipeline, pipeline_jobs, pipeline_monitor})
  end

 @doc """
  Updates one ref monitor based on `{%Project, %Pipeline, [%PipelineJobs], %PipelineMonitor}`.

  project, pipeline, and pipeline jobs should be migrated before
    calling upsert_ref_monitor

  1. source_key_project_monitor is called from a http post
  2. pipeline_monitor is created/updated during the http_post
  3. upsert_ref_monitor is called to set up the dashboard

  Returns `[%DashboardBadgeStatus]`
  """
  def upsert_ref_monitor({project, pipeline, pipeline_jobs, pipeline_monitor} = project_pipeline_monitor) do

    Logger.info fn ->
      "upsert_ref_monitor/1 project id: #{project.id} pipeline_id: #{pipeline.id}"
    end
    
    project_id = project.id
    pipeline_id = pipeline.id

    # initialize the dashboard on build pipeline only
    if pipeline_monitor.pipeline_type == "build" do
      CncfDashboardApi.GitlabMonitor.Dashboard.initialize_ref_monitor(project_id)
    end

    #  get all clouds
    clouds = Repo.all(from c in CncfDashboardApi.Clouds)

    if pipeline.release_type == "stable" do
      pipeline_order = 1
    else
      pipeline_order = 2
    end

    # TODO if never given a release status for the pipeline, raise an error

    # if  deploy pipline, use the target project for the refmonitor
    Logger.info fn ->
      " upsert_ref_monitor pipeline_monitor.internal_build_pipeline_id: #{inspect(pipeline_monitor.internal_build_pipeline_id)}"
    end
    Logger.info fn ->
      " upsert_ref_monitor all build pipeline_monitors: #{inspect(Repo.all(CncfDashboardApi.PipelineMonitor) )}"
    end

    {target_pm, target_pl} = target_pipeline_info(pipeline_monitor, pipeline)

    rm_record = CncfDashboardApi.GitlabMonitor.Dashboard.upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, pipeline_order)


    job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("project")
    dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm_record,
                                                                       target_pl.ref,
                                                                       CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, false, "", target_pm.pipeline_id),
                                                                       CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, target_pm.pipeline_id),
                                                                       1)

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

    cc = Repo.all(from p in CncfDashboardApi.Projects, where: p.name == "cross-cloud") |> List.last
    Logger.info fn ->
      "cross_cloud project: #{inspect(cc)}"
    end

    cp = Repo.all(from p in CncfDashboardApi.Projects, where: p.name == "cross-project") |> List.first
    Logger.info fn ->
      "cross_project project: #{inspect(cp)}"
    end

    #loop through all clouds
    posted_clouds = deploy_pipeline_monitors |> Enum.uniq_by(fn(x) -> x.cloud end) |> Enum.reduce([], fn(x,acc)-> [x.cloud | acc] end)
    Logger.info fn ->
      "posted_clouds : #{inspect(posted_clouds)}"
    end

    cloud_list = Repo.all(from cd1 in CncfDashboardApi.Clouds, where: cd1.active == true, where: cd1.cloud_name in ^posted_clouds, order_by: [cd1.order]) 
    Logger.info fn ->
      "filtered cloud_list : #{inspect(cloud_list)}"
    end

    #only loop through clouds that have deploy pipeline monitors
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
        job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-cloud")
        cc_status = CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, cross_cloud_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_cloud_pipeline_monitor.pipeline_id)
        cc_deploy_url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, cross_cloud_pipeline_monitor.child_pipeline, cross_cloud_pipeline_monitor.pipeline_id)
      end

      Logger.info fn ->
        "cross_project_pipeline_monitor: #{inspect(cross_project_pipeline_monitor)}"
      end

      if cross_project_pipeline_monitor do
        job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-project")
        cp_status = CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, cross_project_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_project_pipeline_monitor.pipeline_id)
        cp_deploy_url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, cross_project_pipeline_monitor.child_pipeline, cross_project_pipeline_monitor.pipeline_id)
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

      # ticket #230
      if status == "initial" do
        Logger.error fn ->
          "invalid status for pipline: #{inspect(status)}, #{inspect(status)}"
        end
      else

    dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm_record,
                                                                       target_pl.ref,
                                                                       status,
                                                                       deploy_url,
                                                                       cloud_order)

      end
    end)
  end


end
