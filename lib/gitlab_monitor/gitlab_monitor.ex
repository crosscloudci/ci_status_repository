require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor do
  import Ecto.Query
  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    monitor = CncfDashboardApi.Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                                        where: skpm.id == ^source_key_project_monitor_id) |> List.first
    # field :source_project_id, :string
    # field :source_pipeline_id, :string
    # field :source_pipeline_job_id, :string
    # field :pipeline_release_type, :string
    # field :active, :boolean, default: true
    # migrate project
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_project(monitor.source_project_id) 

    # TODO get the local project id
    source_key_project = CncfDashboardApi.Repo.all(from skp in CncfDashboardApi.SourceKeyProjects, 
                                                   where: skp.source_id == ^monitor.source_project_id) |> List.first

    # TODO call pipeline Data migration
    {:ok, upsert_count, pipeline_map} = CncfDashboardApi.GitlabMigrations.upsert_pipeline(monitor.source_project_id, monitor.source_pipeline_id) 
    # # TODO set the project id in the pipeline monitor source of truth
    # changeset = CncfDashboardApi.PipelineMonitor.changeset(%CncfDashboardApi.PipelineMonitor{}, %{project_id: source_key_project.new_id})
    # CncfDashboardApi.Repo.insert(changeset)

    # TODO get local pipeline id

    # TODO start polling
     
    # TODO determine pipeline type
    
    # TODO set the pipeline id, running = true, release_type, pipeline_type  in the pipeline monitor source of truth
    
    # TODO call dashboard channel
    
    # TODO update last updated
    
    # case Repo.insert(changeset) do
    #   {:ok, source_key_project_monitor} ->
    #     conn
    #     |> put_status(:created)
    #     |> put_resp_header("location", source_key_project_monitor_path(conn, :show, source_key_project_monitor))
    #     |> render("show.json", source_key_project_monitor: source_key_project_monitor)
    #   {:error, changeset} ->
    #     conn
    #     |> put_status(:unprocessable_entity)
    #     |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    # end
    # put local project id in pipeline_monitor
    #
    # field :pipeline_id, :integer
    # field :running, :boolean, default: false
    # field :release_type, :string
    # field :pipeline_type, :string
    # field :project_id, :integer
    # call monitor pipleine
  end
end
