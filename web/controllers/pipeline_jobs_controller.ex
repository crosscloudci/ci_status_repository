defmodule CncfDashboardApi.PipelineJobsController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.PipelineJobs

  def index(conn, _params) do
    pipeline_jobs = Repo.all(PipelineJobs)
    render(conn, "index.json", pipeline_jobs: pipeline_jobs)
  end

  def create(conn, %{"pipeline_jobs" => pipeline_jobs_params}) do
    changeset = PipelineJobs.changeset(%PipelineJobs{}, pipeline_jobs_params)

    case Repo.insert(changeset) do
      {:ok, pipeline_jobs} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", pipeline_jobs_path(conn, :show, pipeline_jobs))
        |> render("show.json", pipeline_jobs: pipeline_jobs)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    pipeline_jobs = Repo.get!(PipelineJobs, id)
    render(conn, "show.json", pipeline_jobs: pipeline_jobs)
  end

  def update(conn, %{"id" => id, "pipeline_jobs" => pipeline_jobs_params}) do
    pipeline_jobs = Repo.get!(PipelineJobs, id)
    changeset = PipelineJobs.changeset(pipeline_jobs, pipeline_jobs_params)

    case Repo.update(changeset) do
      {:ok, pipeline_jobs} ->
        render(conn, "show.json", pipeline_jobs: pipeline_jobs)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    pipeline_jobs = Repo.get!(PipelineJobs, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(pipeline_jobs)

    send_resp(conn, :no_content, "")
  end
end
