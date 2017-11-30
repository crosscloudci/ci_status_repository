defmodule CncfDashboardApi.DashboardControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.Dashboard
  import CncfDashboardApi.Factory
  @valid_attrs %{ref: "some content", status: "some content"}
  @invalid_attrs %{}


  # setup %{conn: conn} do
  #   # {:ok, conn: CncfDashboardApi.ConnCase.guardian_login(%{user: :user}) |> put_req_header("accept", "application/json")}
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end
  setup %{conn: conn} = config do
    signed_conn = Guardian.Plug.api_sign_in(conn, nil)
    {:ok, conn: signed_conn}
  end

  # @tag :wip
  # @tag :authenticated
  @tag :login
  test "lists all entries on index", %{conn: conn} do
    IO.puts "conn: #{inspect(conn)}"
    # conn = conn.guardian_login(nil)
    {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project)
    conn = get conn, dashboard_path(conn, :index)
    # cloud_list = json_response(conn, 200)["dashboard"]["clouds"] |> List.first
    dashboard = json_response(conn, 200)
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
      "repository_url" => _,
      "order" => _,
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
          "status" => _}]}]}] = json_response(conn, 200)["dashboard"]["projects"]

          assert [%{"cloud_id" => _,
            "cloud_name" => _,
          }] = json_response(conn, 200)["dashboard"]["clouds"] |> Enum.take(1)
  end

end
