defmodule CncfDashboardApi.DashboardBadgeStatusController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.DashboardBadgeStatus

  def index(conn, _params) do
    dashboard_badge_status = Repo.all(DashboardBadgeStatus)
    render(conn, "index.json", dashboard_badge_status: dashboard_badge_status)
  end

  def create(conn, %{"dashboard_badge_status" => dashboard_badge_status_params}) do
    changeset = DashboardBadgeStatus.changeset(%DashboardBadgeStatus{}, dashboard_badge_status_params)

    case Repo.insert(changeset) do
      {:ok, dashboard_badge_status} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", dashboard_badge_status_path(conn, :show, dashboard_badge_status))
        |> render("show.json", dashboard_badge_status: dashboard_badge_status)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    dashboard_badge_status = Repo.get!(DashboardBadgeStatus, id)
    render(conn, "show.json", dashboard_badge_status: dashboard_badge_status)
  end

  def update(conn, %{"id" => id, "dashboard_badge_status" => dashboard_badge_status_params}) do
    dashboard_badge_status = Repo.get!(DashboardBadgeStatus, id)
    changeset = DashboardBadgeStatus.changeset(dashboard_badge_status, dashboard_badge_status_params)

    case Repo.update(changeset) do
      {:ok, dashboard_badge_status} ->
        render(conn, "show.json", dashboard_badge_status: dashboard_badge_status)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    dashboard_badge_status = Repo.get!(DashboardBadgeStatus, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(dashboard_badge_status)

    send_resp(conn, :no_content, "")
  end
end
