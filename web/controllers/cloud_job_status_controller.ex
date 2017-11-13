defmodule CncfDashboardApi.CloudJobStatusController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.CloudJobStatus

  def index(conn, _params) do
    cloud_job_status = Repo.all(CloudJobStatus)
    render(conn, "index.json", cloud_job_status: cloud_job_status)
  end

  def create(conn, %{"cloud_job_status" => cloud_job_status_params}) do
    changeset = CloudJobStatus.changeset(%CloudJobStatus{}, cloud_job_status_params)

    case Repo.insert(changeset) do
      {:ok, cloud_job_status} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", cloud_job_status_path(conn, :show, cloud_job_status))
        |> render("show.json", cloud_job_status: cloud_job_status)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    cloud_job_status = Repo.get!(CloudJobStatus, id)
    render(conn, "show.json", cloud_job_status: cloud_job_status)
  end

  def update(conn, %{"id" => id, "cloud_job_status" => cloud_job_status_params}) do
    cloud_job_status = Repo.get!(CloudJobStatus, id)
    changeset = CloudJobStatus.changeset(cloud_job_status, cloud_job_status_params)

    case Repo.update(changeset) do
      {:ok, cloud_job_status} ->
        render(conn, "show.json", cloud_job_status: cloud_job_status)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    cloud_job_status = Repo.get!(CloudJobStatus, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(cloud_job_status)

    send_resp(conn, :no_content, "")
  end
end
