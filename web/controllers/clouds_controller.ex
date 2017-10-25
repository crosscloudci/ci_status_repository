defmodule CncfDashboardApi.CloudsController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.Clouds

  def index(conn, _params) do
    clouds = Repo.all(Clouds)
    render(conn, "index.json", clouds: clouds)
  end

  def create(conn, %{"clouds" => clouds_params}) do
    changeset = Clouds.changeset(%Clouds{}, clouds_params)

    case Repo.insert(changeset) do
      {:ok, clouds} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", clouds_path(conn, :show, clouds))
        |> render("show.json", clouds: clouds)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    clouds = Repo.get!(Clouds, id)
    render(conn, "show.json", clouds: clouds)
  end

  def update(conn, %{"id" => id, "clouds" => clouds_params}) do
    clouds = Repo.get!(Clouds, id)
    changeset = Clouds.changeset(clouds, clouds_params)

    case Repo.update(changeset) do
      {:ok, clouds} ->
        render(conn, "show.json", clouds: clouds)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    clouds = Repo.get!(Clouds, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(clouds)

    send_resp(conn, :no_content, "")
  end
end
