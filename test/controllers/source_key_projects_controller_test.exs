defmodule CncfDashboardApi.SourceKeyProjectsControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.SourceKeyProjects
  @valid_attrs %{new_id: 42, source_id: "some content", source_name: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, source_key_projects_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    source_key_projects = Repo.insert! %SourceKeyProjects{}
    conn = get conn, source_key_projects_path(conn, :show, source_key_projects)
    assert json_response(conn, 200)["data"] == %{"id" => source_key_projects.id,
      "source_id" => source_key_projects.source_id,
      "new_id" => source_key_projects.new_id,
      "source_name" => source_key_projects.source_name}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, source_key_projects_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, source_key_projects_path(conn, :create), source_key_projects: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(SourceKeyProjects, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, source_key_projects_path(conn, :create), source_key_projects: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    source_key_projects = Repo.insert! %SourceKeyProjects{}
    conn = put conn, source_key_projects_path(conn, :update, source_key_projects), source_key_projects: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(SourceKeyProjects, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    source_key_projects = Repo.insert! %SourceKeyProjects{}
    conn = put conn, source_key_projects_path(conn, :update, source_key_projects), source_key_projects: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    source_key_projects = Repo.insert! %SourceKeyProjects{}
    conn = delete conn, source_key_projects_path(conn, :delete, source_key_projects)
    assert response(conn, 204)
    refute Repo.get(SourceKeyProjects, source_key_projects.id)
  end
end
