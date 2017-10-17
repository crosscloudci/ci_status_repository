defmodule CncfDashboardApi.SourceKeyPipelineJobsController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.SourceKeyPipelineJobs

  def index(conn, _params) do
    source_key_pipeline_jobs = Repo.all(SourceKeyPipelineJobs)
    render(conn, "index.json", source_key_pipeline_jobs: source_key_pipeline_jobs)
  end

  def create(conn, %{"source_key_pipeline_jobs" => source_key_pipeline_jobs_params}) do
    changeset = SourceKeyPipelineJobs.changeset(%SourceKeyPipelineJobs{}, source_key_pipeline_jobs_params)

    case Repo.insert(changeset) do
      {:ok, source_key_pipeline_jobs} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", source_key_pipeline_jobs_path(conn, :show, source_key_pipeline_jobs))
        |> render("show.json", source_key_pipeline_jobs: source_key_pipeline_jobs)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    source_key_pipeline_jobs = Repo.get!(SourceKeyPipelineJobs, id)
    render(conn, "show.json", source_key_pipeline_jobs: source_key_pipeline_jobs)
  end

  def update(conn, %{"id" => id, "source_key_pipeline_jobs" => source_key_pipeline_jobs_params}) do
    source_key_pipeline_jobs = Repo.get!(SourceKeyPipelineJobs, id)
    changeset = SourceKeyPipelineJobs.changeset(source_key_pipeline_jobs, source_key_pipeline_jobs_params)

    case Repo.update(changeset) do
      {:ok, source_key_pipeline_jobs} ->
        render(conn, "show.json", source_key_pipeline_jobs: source_key_pipeline_jobs)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    source_key_pipeline_jobs = Repo.get!(SourceKeyPipelineJobs, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(source_key_pipeline_jobs)

    send_resp(conn, :no_content, "")
  end
end
