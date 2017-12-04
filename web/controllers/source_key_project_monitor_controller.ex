require IEx;
defmodule CncfDashboardApi.SourceKeyProjectMonitorController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.SourceKeyProjectMonitor

  def index(conn, _params) do
    source_key_project_monitor = Repo.all(SourceKeyProjectMonitor)
    render(conn, "index.json", source_key_project_monitor: source_key_project_monitor)
  end

  def create(conn, %{"source_key_project_monitor" => source_key_project_monitor_params}) do
    changeset = SourceKeyProjectMonitor.changeset(%SourceKeyProjectMonitor{}, source_key_project_monitor_params)

    case Repo.insert(changeset) do
      {:ok, source_key_project_monitor} ->
        # start polling
        CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(source_key_project_monitor.id)
        {_pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(source_key_project_monitor.id) 
        project = Repo.get!(CncfDashboardApi.Projects, pm_record.project_id)
        
        CncfDashboardApi.Polling.Supervisor.Pipeline.start_pipeline(source_key_project_monitor.id, source_key_project_monitor.id, project.timeout * 1000) 
        # Process.sleep(13000)
        conn
        |> put_status(:created)
        |> put_resp_header("location", source_key_project_monitor_path(conn, :show, source_key_project_monitor))
        |> render("show.json", source_key_project_monitor: source_key_project_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    source_key_project_monitor = Repo.get!(SourceKeyProjectMonitor, id)
    render(conn, "show.json", source_key_project_monitor: source_key_project_monitor)
  end

  def update(conn, %{"id" => id, "source_key_project_monitor" => source_key_project_monitor_params}) do
    source_key_project_monitor = Repo.get!(SourceKeyProjectMonitor, id)
    changeset = SourceKeyProjectMonitor.changeset(source_key_project_monitor, source_key_project_monitor_params)

    case Repo.update(changeset) do
      {:ok, source_key_project_monitor} ->
        render(conn, "show.json", source_key_project_monitor: source_key_project_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    source_key_project_monitor = Repo.get!(SourceKeyProjectMonitor, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(source_key_project_monitor)

    send_resp(conn, :no_content, "")
  end
end
