defmodule CncfDashboardApi.PipelineMonitorController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.PipelineMonitor

  def index(conn, _params) do
    pipeline_monitor = Repo.all(PipelineMonitor)
    render(conn, "index.json", pipeline_monitor: pipeline_monitor)
  end

  def create(conn, %{"pipeline_monitor" => pipeline_monitor_params}) do
    changeset = PipelineMonitor.changeset(%PipelineMonitor{}, pipeline_monitor_params)

    case Repo.insert(changeset) do
      {:ok, pipeline_monitor} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", pipeline_monitor_path(conn, :show, pipeline_monitor))
        |> render("show.json", pipeline_monitor: pipeline_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    pipeline_monitor = Repo.get!(PipelineMonitor, id)
    render(conn, "show.json", pipeline_monitor: pipeline_monitor)
  end

  def update(conn, %{"id" => id, "pipeline_monitor" => pipeline_monitor_params}) do
    pipeline_monitor = Repo.get!(PipelineMonitor, id)
    changeset = PipelineMonitor.changeset(pipeline_monitor, pipeline_monitor_params)

    case Repo.update(changeset) do
      {:ok, pipeline_monitor} ->
        render(conn, "show.json", pipeline_monitor: pipeline_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    pipeline_monitor = Repo.get!(PipelineMonitor, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(pipeline_monitor)

    send_resp(conn, :no_content, "")
  end
end
