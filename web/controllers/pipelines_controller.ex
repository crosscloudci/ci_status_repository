require IEx;
defmodule CncfDashboardApi.PipelinesController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.Pipelines

  def index(conn, _params) do
    # pipelines = Repo.all(Pipelines)
    pipelines = CncfDashboardApi.Repo.all(from pl in CncfDashboardApi.Pipelines, 
                                          preload: [:pipeline_jobs]) 
    render(conn, "index.json", pipelines: pipelines)
  end

  def create(conn, %{"pipelines" => pipelines_params}) do
    changeset = Pipelines.changeset(%Pipelines{}, pipelines_params)

    case Repo.insert(changeset) do
      {:ok, pipelines} ->
        pipelines = CncfDashboardApi.Repo.all(from pl in CncfDashboardApi.Pipelines, 
                                              where: pl.id == ^pipelines.id, preload: [:pipeline_jobs]) 
                                              |> List.first
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
    # pipelines = Repo.get!(Pipelines, id)
    pipelines = CncfDashboardApi.Repo.all(from pl in CncfDashboardApi.Pipelines, 
                                          where: pl.id == ^id, preload: [:pipeline_jobs]) 
                                          |> List.first
    case pipelines do
      %{} -> 
        render(conn, "show.json", pipelines: pipelines)
      nil ->
        conn
        |> put_status(404)
        |> render(CncfDashboardApi.ErrorView, "404.json", pipelines: pipelines)
    end
  end

  def update(conn, %{"id" => id, "pipelines" => pipelines_params}) do
    # pipelines = Repo.get!(Pipelines, id)
    pipelines = CncfDashboardApi.Repo.all(from pl in CncfDashboardApi.Pipelines, 
                                          where: pl.id == ^id, preload: [:pipeline_jobs]) 
                                          |> List.first
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
    # pipelines = Repo.get!(Pipelines, id)
    pipelines = CncfDashboardApi.Repo.all(from pl in CncfDashboardApi.Pipelines, 
                                          where: pl.id == ^id, preload: [:pipeline_jobs]) 
                                          |> List.first

                                          # Here we use delete! (with a bang) because we expect
                                          # it to always work (and if it does not, it will raise).
    Repo.delete!(pipelines)

    send_resp(conn, :no_content, "")
  end
end
