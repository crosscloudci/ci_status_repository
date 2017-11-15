defmodule CncfDashboardApi.RefMonitorController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.RefMonitor

  def index(conn, _params) do
    ref_monitor = Repo.all(RefMonitor)
    render(conn, "index.json", ref_monitor: ref_monitor)
  end

  def create(conn, %{"ref_monitor" => ref_monitor_params}) do
    changeset = RefMonitor.changeset(%RefMonitor{}, ref_monitor_params)

    case Repo.insert(changeset) do
      {:ok, ref_monitor} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ref_monitor_path(conn, :show, ref_monitor))
        |> render("show.json", ref_monitor: ref_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    ref_monitor = Repo.get!(RefMonitor, id)
    render(conn, "show.json", ref_monitor: ref_monitor)
  end

  def update(conn, %{"id" => id, "ref_monitor" => ref_monitor_params}) do
    ref_monitor = Repo.get!(RefMonitor, id)
    changeset = RefMonitor.changeset(ref_monitor, ref_monitor_params)

    case Repo.update(changeset) do
      {:ok, ref_monitor} ->
        render(conn, "show.json", ref_monitor: ref_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ref_monitor = Repo.get!(RefMonitor, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(ref_monitor)

    send_resp(conn, :no_content, "")
  end
end
