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
    |> upsert_gitlab_to_ref_monitor 
    CncfDashboardApi.GitlabMonitor.Dashboard.broadcast()
    :ok
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
    # get the local provision pipeline
    source_key_provision_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                   where: skp.source_id == ^monitor.provision_pipeline_id) 
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
                                   
    Logger.info fn ->
      "migrate_source_key_monitor: source_key_provision_pipeline : #{inspect(source_key_provision_pipeline)}"
    end
    {:ok, {monitor, source_key_project, source_key_pipeline, source_key_project_monitor_id, target_source_key_pipeline, source_key_provision_pipeline}}
  end

 @doc """
  Migrates the source key pipeline_monitor into the internal pipeline monitor based on `{%monitor, %source_key_project, %source_key_pipeline, source_key_project_monitor_id}`.

  Returns `[%SourceKeyProjects, %SourceKeyPipelines]`
  """
  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    update_dashboard(source_key_project_monitor_id)
  end

  def upsert_pipeline_monitor_info({:ok, source_key_project_info}) do
    upsert_pipeline_monitor_info(source_key_project_info)
  end

 @doc """
  Migrates the source key pipeline_monitor into the internal pipeline monitor based on `source_key_project_monitor_id`.

  Returns `[%SourceKeyProjects, %SourceKeyPipelines]`
  """
  def upsert_pipeline_monitor_info({monitor, source_key_project, source_key_pipeline, source_key_project_monitor_id, target_source_key_pipeline, source_key_provision_pipeline} = source_key_project_info) do

    CncfDashboardApi.GitlabMonitor.Dashboard.last_checked()

    pipeline_type =  CncfDashboardApi.GitlabMonitor.Pipeline.pipeline_type(source_key_project.new_id) 

    alternate_release = if (monitor.pipeline_release_type == "stable"), do: "head", else: "stable"

    #TODO we now can monitor, for the same pipeline, multiple release types that are the same (two for stable but that have different *kubernetes* release types or archs)
    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      release_type: alternate_release} 
      |> find_by([:pipeline_id, :project_id, :release_type])

      case pm_found do
        :found -> 
          # raise "You may not monitor the same project and pipeline for two different branches"
          Logger.info fn ->
            "upsert_pipeline_monitor_info Monitoring the same project and pipeline for two different branches #{inspect(source_key_project)}"
          end
        _ -> :ok
      end

      case pipeline_type do
        "deploy" -> 
          Logger.info fn ->
            "upsert_pipeline_monitor_info source_key_provision_pipeline: #{inspect(source_key_provision_pipeline)}"
          end

          # provision_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.provision_pipeline_monitor_by_deploy_pipeline_monitor(pm_record)
          provision_pipeline_id = source_key_provision_pipeline.new_id
          kubernetes_release_type = monitor.kubernetes_release_type
          Logger.info fn ->
            "upsert_pipeline_monitor_info provision_pipeline_id, kubernetes_release_type #{inspect(provision_pipeline_id)} #{inspect(kubernetes_release_type)} "
          end
        "provision" -> 
          provision_pipeline_id = source_key_pipeline.new_id 
          kubernetes_release_type = monitor.kubernetes_release_type 
        "build" ->
          provision_pipeline_id = nil 
          kubernetes_release_type = monitor.kubernetes_release_type 
        _ ->
          Logger.error fn ->
            "legacy pipeline (no pipeline_type): #{inspect(monitor)}"
          end
      end
      # Insert only if pipeline, project, and release type and kubernetes release type do not exist
      # else update
          Logger.info fn ->
            "upsert_pipeline_monitor_info source_key_pipeline: #{inspect(source_key_pipeline)}"
          end

      {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
        project_id: source_key_project.new_id,
        pipeline_type: pipeline_type,
        release_type: monitor.pipeline_release_type,
        kubernetes_release_type: monitor.kubernetes_release_type } 
        |> find_by([:pipeline_id, :project_id, :pipeline_type, :release_type, :kubernetes_release_type])

      Logger.info fn ->
        "pm_record #{inspect(pm_record)}"
      end

      changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, 
                                                               %{project_id: source_key_project.new_id,
                                                                 pipeline_id: source_key_pipeline.new_id,
                                                                 running: true,
                                                                 release_type: monitor.pipeline_release_type,
                                                                 pipeline_type: pipeline_type,
                                                                 cloud: monitor.cloud,
                                                                 child_pipeline: monitor.child_pipeline,
                                                                 target_project_name: monitor.target_project_name,
                                                                 kubernetes_release_type: kubernetes_release_type,
                                                                 test_env: kubernetes_release_type,
                                                                 provision_pipeline_id: provision_pipeline_id,
                                                                 arch: monitor.arch,
                                                                 internal_build_pipeline_id: target_source_key_pipeline.new_id
                                                               })
      Logger.info fn ->
        "changeset to be upserted:  #{inspect(changeset)}"
      end

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

    project_pipeline_info = CncfDashboardApi.GitlabMonitor.Pipeline.project_pipeline_info(source_key_project.new_id, source_key_pipeline.new_id)
  end

 @doc """
  Updates one ref monitor based on `project_id` and  `pipeline_id`.

  project, pipeline, and pipeline jobs should be migrated before
    calling upsert_gitlab_to_ref_monitor 

  1. source_key_project_monitor is called from a http post
  2. pipeline_monitor is created/updated during the http_post
  3. upsert_gitlab_to_ref_monitor is called to set up the dashboard

  Returns `[%DashboardBadgeStatus]`
  """
  def upsert_gitlab_to_ref_monitor(project_id, pipeline_id) do
    Logger.info fn ->
      "upsert_ref_monitor project id: #{project_id} pipeline_id: #{pipeline_id}"
    end
    project_pipeline_info = CncfDashboardApi.GitlabMonitor.Pipeline.project_pipeline_info(project_id, pipeline_id)
    upsert_gitlab_to_ref_monitor(project_pipeline_info)
  end

  def upsert_gitlab_to_ref_monitor({:ok, project, pipeline, pipeline_jobs, pipeline_monitor} = project_pipeline_monitor) do
    upsert_gitlab_to_ref_monitor({project, pipeline, pipeline_jobs, pipeline_monitor})
  end

 @doc """
  Updates one ref monitor based on `{%Project, %Pipeline, [%PipelineJobs], %PipelineMonitor}`.

  project, pipeline, and pipeline jobs should be migrated before
    calling upsert_gitlab_to_ref_monitor 

  1. source_key_project_monitor is called from a http post
  2. pipeline_monitor is created/updated during the http_post
  3. upsert_gitlab_to_ref_monitor is called to set up the dashboard

  Returns `[%DashboardBadgeStatus]`
  """
  def upsert_gitlab_to_ref_monitor({project, pipeline, pipeline_jobs, pipeline_monitor} = project_pipeline_monitor) do

    Logger.info fn ->
      "upsert_ref_monitor/1 project id: #{project.id} pipeline_id: #{pipeline.id}"
    end
    
    project_id = project.id
    # pipeline_id = pipeline.id

    # initialize the dashboard on build pipeline only
    if pipeline_monitor.pipeline_type == "build" do
      CncfDashboardApi.GitlabMonitor.Dashboard.initialize_ref_monitor(project_id)
    end

    CncfDashboardApi.GitlabMonitor.PMToDashboard.pm_stage_to_project_rows({pipeline_monitor.pipeline_type, pipeline_monitor})
    |> CncfDashboardApi.GitlabMonitor.PMToDashboard.project_rows_to_columns()

  end

  def cloud_order_by_name(cloud_name) do
    Logger.info fn ->
      "cloud_order_by_name: #{inspect(cloud_name)}"
    end
    {p_found, c_record} = %CncfDashboardApi.Clouds{cloud_name: cloud_name } |> find_by([:cloud_name])
    order = if p_found do
      c_record.order + 1 # clouds start with 2 wrt badge status
    else
      :error
    end
  end

end
