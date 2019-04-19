defmodule CncfDashboardApi.RefMonitorControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.RefMonitor
  @valid_attrs %{order: 42, pipeline_id: 42, project_id: 42, ref: "some content", release_type: "some content", sha: "some content", status: "some content", test_env: "master"}
  @invalid_attrs %{}

  setup %{conn: conn} = config do
    signed_conn = Guardian.Plug.api_sign_in(conn, nil)
    {:ok, conn: signed_conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, ref_monitor_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  @tag :wip
  test "shows chosen resource", %{conn: conn} do
    ref_monitor = Repo.insert! %RefMonitor{}
    conn = get conn, ref_monitor_path(conn, :show, ref_monitor)
    assert json_response(conn, 200)["data"] == %{"id" => ref_monitor.id,
      "ref" => ref_monitor.ref,
      "status" => ref_monitor.status,
      "sha" => ref_monitor.sha,
      "release_type" => ref_monitor.release_type,
      "project_id" => ref_monitor.project_id,
      "order" => ref_monitor.order,
      "pipeline_id" => ref_monitor.id,
      "head_commit" => nil, 
      "jobs" => [], 
      "stable_tag" => nil,
      "test_env" => nil, 
      "arch" => nil, 
      "kubernetes_release_type" => nil
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn =  get conn, ref_monitor_path(conn, :show, -1)
    assert %{"errors" => _} = json_response(conn, 404) 
    # assert_error_sent 404, fn ->
    #   get conn, ref_monitor_path(conn, :show, -1)
    # end
  end

  @tag :wip
  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, ref_monitor_path(conn, :create), ref_monitor: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(RefMonitor, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, ref_monitor_path(conn, :create), ref_monitor: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  @tag :wip
  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    ref_monitor = Repo.insert! %RefMonitor{}
    conn = put conn, ref_monitor_path(conn, :update, ref_monitor), ref_monitor: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(RefMonitor, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    ref_monitor = Repo.insert! %RefMonitor{}
    conn = put conn, ref_monitor_path(conn, :update, ref_monitor), ref_monitor: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    ref_monitor = Repo.insert! %RefMonitor{}
    conn = delete conn, ref_monitor_path(conn, :delete, ref_monitor)
    assert response(conn, 204)
    refute Repo.get(RefMonitor, ref_monitor.id)
  end
end
