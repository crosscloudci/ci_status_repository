defmodule CncfDashboardApi.ProjectsController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.Projects

  def index(conn, _params) do
    projects = Repo.all(Projects)
    render(conn, "index.json", projects: projects)
  end

  def create(conn, %{"projects" => projects_params}) do
    changeset = Projects.changeset(%Projects{}, projects_params)

    case Repo.insert(changeset) do
      {:ok, projects} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", projects_path(conn, :show, projects))
        |> render("show.json", projects: projects)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    projects = Repo.get!(Projects, id)
    render(conn, "show.json", projects: projects)
  end

  def update(conn, %{"id" => id, "projects" => projects_params}) do
    projects = Repo.get!(Projects, id)
    changeset = Projects.changeset(projects, projects_params)

    case Repo.update(changeset) do
      {:ok, projects} ->
        render(conn, "show.json", projects: projects)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    projects = Repo.get!(Projects, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(projects)

    send_resp(conn, :no_content, "")
  end
end
