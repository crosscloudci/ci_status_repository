defmodule CncfDashboardApi.BuildJobStatusController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.BuildJobStatus

  def index(conn, _params) do
    build_job_status = Repo.all(BuildJobStatus)
    render(conn, "index.json", build_job_status: build_job_status)
  end

  def create(conn, %{"build_job_status" => build_job_status_params}) do
    changeset = BuildJobStatus.changeset(%BuildJobStatus{}, build_job_status_params)

    case Repo.insert(changeset) do
      {:ok, build_job_status} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", build_job_status_path(conn, :show, build_job_status))
        |> render("show.json", build_job_status: build_job_status)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    build_job_status = Repo.get!(BuildJobStatus, id)
    render(conn, "show.json", build_job_status: build_job_status)
  end

  def update(conn, %{"id" => id, "build_job_status" => build_job_status_params}) do
    build_job_status = Repo.get!(BuildJobStatus, id)
    changeset = BuildJobStatus.changeset(build_job_status, build_job_status_params)

    case Repo.update(changeset) do
      {:ok, build_job_status} ->
        render(conn, "show.json", build_job_status: build_job_status)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    build_job_status = Repo.get!(BuildJobStatus, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(build_job_status)

    send_resp(conn, :no_content, "")
  end
end
