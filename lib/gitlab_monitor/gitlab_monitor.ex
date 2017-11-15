require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor do
  import Ecto.Query
  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    monitor = CncfDashboardApi.Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                                        where: skpm.id == ^source_key_project_monitor_id) |> List.first
    # migrate project
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_project(monitor.source_project_id) 

    # get the local project id
    source_key_project = CncfDashboardApi.Repo.all(from skp in CncfDashboardApi.SourceKeyProjects, 
                                                   where: skp.source_id == ^monitor.source_project_id) |> List.first

    # migrate pipeline 
    {:ok, upsert_count, pipeline_map} = CncfDashboardApi.GitlabMigrations.upsert_pipeline(monitor.source_project_id, monitor.source_pipeline_id) 

    # get the local pipeline
    source_key_pipeline = CncfDashboardApi.Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.source_pipeline_id) |> List.first

    
    # determine pipeline type
    case CncfDashboardApi.GitlabMonitor.is_deploy_pipeline_type(source_key_project.new_id) do
      true -> pipeline_type = "deploy"
      _ -> pipeline_type = "build"
    end

    # saved curl data (source key project monitor)                                                
    # field :source_project_id, :string
    # field :source_pipeline_id, :string
    # field :source_pipeline_job_id, :string
    # field :pipeline_release_type, :string
    # field :active, :boolean, default: true
    
    # pipeline monitor fields
    # field :pipeline_id, :integer
    # field :running, :boolean, default: false
    # field :release_type, :string
    # field :pipeline_type, :string
    # field :project_id, :integer
    
    changeset = CncfDashboardApi.PipelineMonitor.changeset(%CncfDashboardApi.PipelineMonitor{}, 
                                                           %{project_id: source_key_project.new_id,
                                                             pipeline_id: source_key_pipeline.new_id,
                                                             running: true,
                                                             release_type: monitor.pipeline_release_type,
                                                             pipeline_type: pipeline_type 
                                                           })
                                                           
    # TODO insert only if pipeline, project, and release type do not exist
    # else update
    CncfDashboardApi.Repo.insert(changeset)

    # migrate all jobs for the pipeline 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(monitor.source_project_id |> String.to_integer, 
                                                           monitor.source_pipeline_id |> String.to_integer)

    # TODO if no build job status and cloud job status records for passed project, create/default to running or N/A

    # TODO start polling
    
    # Call dashboard channel
    CncfDashboardApi.Endpoint.broadcast! "dashboard:*", "new_cross_cloud_call", %{reply: dashboard_response} 

    Logger.info fn ->
      "GitlabMonitor: Broadcasted json"
    end

    # TODO update last updated

  end

  def dashboard_response do
    cloud_list = CncfDashboardApi.Repo.all(from cd1 in CncfDashboardApi.Clouds, 
                                           where: cd1.active == true,
                                           select: %{id: cd1.id, cloud_id: cd1.id, 
                                             name: cd1.cloud_name, cloud_name: cd1.cloud_name}) 
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: pipelines in assoc(projects, :pipelines),
                                         left_join: pipeline_jobs in assoc(pipelines, :pipeline_jobs),
                                         left_join: cloud in assoc(pipeline_jobs, :cloud),
                                         where: projects.active == true,
                                         preload: [pipelines: 
                                                   {pipelines, pipeline_jobs: pipeline_jobs, 
                                                     pipeline_jobs: {pipeline_jobs, cloud: cloud },
                                                   }] )

    with_cloud = %{"clouds" => cloud_list, "projects" => projects} 
    response = CncfDashboardApi.DashboardView.render("index.json", dashboard: with_cloud)
  end

  # projec name is either cross-cloud (cross-cloud handles the deploy pipelines)
  # or other (a build pipeline)
  def is_deploy_pipeline_type(project_id) do
    project = CncfDashboardApi.Repo.all(from skp in CncfDashboardApi.Projects, 
                                        where: skp.id == ^project_id) |> List.first
    if project.name =~ "cross-cloud" do
      true
    else
      false
    end

  end

  # projects, clouds, pipleines, and pipeline jobs should be recently migrated before calling build check
  def build_check(pipeline_id) do
    container = CncfDashboardApi.Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                                          where: pj.pipeline_id == ^pipeline_id)
                |> Enum.find(fn(x) -> x.name =~ "container" end) 
    if container && (container.status == "success" || container.status == "failed") do
      # TODO set running for pipeline monitor where current pipeline_id to false
      # TODO check if build job status = container.status
      #   if not 
      #      update build job status = container.status 
      #      update last updated field on dashboard
      #      message dashboard channel
      #      stop polling process (possible?)
    end
  end
end
