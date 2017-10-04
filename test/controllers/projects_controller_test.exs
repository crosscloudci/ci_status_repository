defmodule CncfDashboardApi.ProjectsControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.Projects
  @valid_attrs %{http_url_to_repo: "some content", name: "some content", ssh_url_to_repo: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, projects_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    projects = Repo.insert! %Projects{}
    conn = get conn, projects_path(conn, :show, projects)
    assert json_response(conn, 200)["data"] == %{"id" => projects.id,
      "name" => projects.name,
      "ssh_url_to_repo" => projects.ssh_url_to_repo,
      "http_url_to_repo" => projects.http_url_to_repo}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, projects_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, projects_path(conn, :create), projects: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Projects, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, projects_path(conn, :create), projects: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    projects = Repo.insert! %Projects{}
    conn = put conn, projects_path(conn, :update, projects), projects: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Projects, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    projects = Repo.insert! %Projects{}
    conn = put conn, projects_path(conn, :update, projects), projects: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    projects = Repo.insert! %Projects{}
    conn = delete conn, projects_path(conn, :delete, projects)
    assert response(conn, 204)
    refute Repo.get(Projects, projects.id)
  end
end
