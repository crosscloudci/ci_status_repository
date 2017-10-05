defmodule CncfDashboardApi.SourceKeyProjectsController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.SourceKeyProjects

  def index(conn, _params) do
    source_key_projects = Repo.all(SourceKeyProjects)
    render(conn, "index.json", source_key_projects: source_key_projects)
  end

  def create(conn, %{"source_key_projects" => source_key_projects_params}) do
    changeset = SourceKeyProjects.changeset(%SourceKeyProjects{}, source_key_projects_params)

    case Repo.insert(changeset) do
      {:ok, source_key_projects} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", source_key_projects_path(conn, :show, source_key_projects))
        |> render("show.json", source_key_projects: source_key_projects)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    source_key_projects = Repo.get!(SourceKeyProjects, id)
    render(conn, "show.json", source_key_projects: source_key_projects)
  end

  def update(conn, %{"id" => id, "source_key_projects" => source_key_projects_params}) do
    source_key_projects = Repo.get!(SourceKeyProjects, id)
    changeset = SourceKeyProjects.changeset(source_key_projects, source_key_projects_params)

    case Repo.update(changeset) do
      {:ok, source_key_projects} ->
        render(conn, "show.json", source_key_projects: source_key_projects)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    source_key_projects = Repo.get!(SourceKeyProjects, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(source_key_projects)

    send_resp(conn, :no_content, "")
  end
end
