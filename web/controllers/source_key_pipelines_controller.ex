defmodule CncfDashboardApi.SourceKeyPipelinesController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.SourceKeyPipelines

  def index(conn, _params) do
    source_key_pipelines = Repo.all(SourceKeyPipelines)
    render(conn, "index.json", source_key_pipelines: source_key_pipelines)
  end

  def create(conn, %{"source_key_pipelines" => source_key_pipelines_params}) do
    changeset = SourceKeyPipelines.changeset(%SourceKeyPipelines{}, source_key_pipelines_params)

    case Repo.insert(changeset) do
      {:ok, source_key_pipelines} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", source_key_pipelines_path(conn, :show, source_key_pipelines))
        |> render("show.json", source_key_pipelines: source_key_pipelines)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    source_key_pipelines = Repo.get!(SourceKeyPipelines, id)
    render(conn, "show.json", source_key_pipelines: source_key_pipelines)
  end

  def update(conn, %{"id" => id, "source_key_pipelines" => source_key_pipelines_params}) do
    source_key_pipelines = Repo.get!(SourceKeyPipelines, id)
    changeset = SourceKeyPipelines.changeset(source_key_pipelines, source_key_pipelines_params)

    case Repo.update(changeset) do
      {:ok, source_key_pipelines} ->
        render(conn, "show.json", source_key_pipelines: source_key_pipelines)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    source_key_pipelines = Repo.get!(SourceKeyPipelines, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(source_key_pipelines)

    send_resp(conn, :no_content, "")
  end
end
