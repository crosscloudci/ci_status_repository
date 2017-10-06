defmodule CncfDashboardApi.PipelinesController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.Pipelines

  def index(conn, _params) do
    pipelines = Repo.all(Pipelines)
    render(conn, "index.json", pipelines: pipelines)
  end

  def create(conn, %{"pipelines" => pipelines_params}) do
    changeset = Pipelines.changeset(%Pipelines{}, pipelines_params)

    case Repo.insert(changeset) do
      {:ok, pipelines} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", pipelines_path(conn, :show, pipelines))
        |> render("show.json", pipelines: pipelines)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    pipelines = Repo.get!(Pipelines, id)
    render(conn, "show.json", pipelines: pipelines)
  end

  def update(conn, %{"id" => id, "pipelines" => pipelines_params}) do
    pipelines = Repo.get!(Pipelines, id)
    changeset = Pipelines.changeset(pipelines, pipelines_params)

    case Repo.update(changeset) do
      {:ok, pipelines} ->
        render(conn, "show.json", pipelines: pipelines)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    pipelines = Repo.get!(Pipelines, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(pipelines)

    send_resp(conn, :no_content, "")
  end
end
