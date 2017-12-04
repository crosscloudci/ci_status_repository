require IEx;
defmodule CncfDashboardApi.ProjectsControllerTest do
  use CncfDashboardApi.ConnCase
  import CncfDashboardApi.Factory

  alias CncfDashboardApi.Projects
  @valid_attrs %{http_url_to_repo: "some content", name: "some content", ssh_url_to_repo: "some content"}
  @invalid_attrs %{}

  # setup %{conn: conn} do
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end

  # setup %{conn: conn} = config do
  #   cond do
  #     config[:login] ->
  #       # user = insert_user()
  #       signed_conn = Guardian.Plug.api_sign_in(conn, nil)
  #       {:ok, conn: signed_conn}
  #     true ->
  #       :ok
  #   end
  # end

  setup %{conn: conn} = config do
    signed_conn = Guardian.Plug.api_sign_in(conn, nil)
    {:ok, conn: signed_conn}
  end

  @tag :wip
  # @tag :login
  test "lists all entries on index", %{conn: conn} do
    projects = insert(:project)
    conn = get conn, projects_path(conn, :index)
    assert  [%{"id" => _,
      "name" => _,
      "project_id" => _,
      "title" => _,
      "caption" => _,
      "url" => _,
      "icon" => _,
      "display_name" => _,
      "sub_title" => _,
      "ssh_url_to_repo" => _,
      "http_url_to_repo" => _,
      "pipelines" => [%{"id" => _,
        "pipeline_id" => _,
        "project_id" => _,
        "status" => _,
        "stable_tag" => _,
        "head_commit" => _,
        "ref" => _,
        "jobs" => [%{"cloud_id" => _, 
          "id" => _, "job_id" => _, 
          "name" => _, 
          "pipeline_id" => _, 
          "project_id" => _, 
          "ref" => _, 
          "status" => _}]}]}] = json_response(conn, 200)["data"]
  end

  test "shows chosen resource", %{conn: conn} do
    projects = insert(:project)
    conn = get conn, projects_path(conn, :show, projects)
    assert  %{"id" => _,
      "name" => _,
      "project_id" => _,
      "title" => _,
      "caption" => _,
      "url" => _,
      "icon" => _,
      "display_name" => _,
      "sub_title" => _,
      "ssh_url_to_repo" => _,
      "http_url_to_repo" => _,
      "pipelines" => [%{"id" => _,
        "pipeline_id" => _,
        "project_id" => _,
        "status" => _,
        "stable_tag" => _,
        "head_commit" => _,
        "ref" => _,
        "jobs" => [%{"cloud_id" => _, 
          "id" => _, "job_id" => _, 
          "name" => _, 
          "pipeline_id" => _, 
          "project_id" => _, 
          "ref" => _, 
          "status" => _}]}]} = json_response(conn, 200)["data"]
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn =  get conn, projects_path(conn, :show, -1)
    assert %{"errors" => _} = json_response(conn, 404) 
    # assert_error_sent 404, fn ->
    #   get conn, projects_path(conn, :show, -1)
    # end
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
    # projects = Repo.insert! %Projects{}
    projects = insert(:project)
    conn = put conn, projects_path(conn, :update, projects), projects: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Projects, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    projects = Repo.insert! %Projects{}
    # projects = insert(:project)
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
