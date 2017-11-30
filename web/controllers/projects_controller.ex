require IEx;
defmodule CncfDashboardApi.ProjectsController do
  use CncfDashboardApi.Web, :controller
  alias CncfDashboardApi.Projects

  def index(conn, _params) do
    # projects = Repo.all(Projects)
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: pipelines in assoc(projects, :pipelines),
                                         left_join: pipeline_jobs in assoc(pipelines, :pipeline_jobs),
                                         left_join: ref_monitors in assoc(projects, :ref_monitors),
                                         left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                                         left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                                         preload: [pipelines: :pipeline_jobs,
                                                   ref_monitors: {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                                     dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                                   }] ) 

    # projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
    #                                      left_join: ref_monitors in assoc(projects, :ref_monitors),
    #                                      left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
    #                                      left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
    #                                      where: projects.active == true,
    #                                      preload: [ref_monitors: 
    #                                                {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
    #                                                  dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
    #                                                }] )
    render(conn, "index.json", projects: projects)
  end

  def create(conn, %{"projects" => projects_params}) do
    changeset = Projects.changeset(%Projects{}, projects_params)

    case Repo.insert(changeset) do
      {:ok, projects} ->
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: pipelines in assoc(projects, :pipelines),
                                         left_join: pipeline_jobs in assoc(pipelines, :pipeline_jobs),
                                         left_join: ref_monitors in assoc(projects, :ref_monitors),
                                         left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                                         left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                                         where: projects.id == ^projects.id, preload: [pipelines: :pipeline_jobs],  
                                         preload: [pipelines: :pipeline_jobs,
                                                   ref_monitors: {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                                     dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                                   }] ) 
                                         |> List.first
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
    # projects = Repo.get!(Projects, id)
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: pipelines in assoc(projects, :pipelines),
                                         left_join: pipeline_jobs in assoc(pipelines, :pipeline_jobs),
                                         left_join: ref_monitors in assoc(projects, :ref_monitors),
                                         left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                                         left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                                         where: projects.id == ^id, preload: [pipelines: :pipeline_jobs],  
                                         preload: [pipelines: :pipeline_jobs,
                                                   ref_monitors: {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                                     dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                                   }] ) 
                                         |> List.first
    case projects do
      %{} -> 
        render(conn, "show.json", projects: projects)
      nil ->
        conn
        |> put_status(404)
        |> render(CncfDashboardApi.ErrorView, "404.json", projects: projects)
    end
  end

  def update(conn, %{"id" => id, "projects" => projects_params}) do
    # projects = Repo.get!(Projects, id)
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: pipelines in assoc(projects, :pipelines),
                                         left_join: pipeline_jobs in assoc(pipelines, :pipeline_jobs),
                                         left_join: ref_monitors in assoc(projects, :ref_monitors),
                                         left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                                         left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                                         where: projects.id == ^id, preload: [pipelines: :pipeline_jobs],  
                                         preload: [pipelines: :pipeline_jobs,
                                                   ref_monitors: {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                                     dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                                   }] ) 
                                         |> List.first
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
