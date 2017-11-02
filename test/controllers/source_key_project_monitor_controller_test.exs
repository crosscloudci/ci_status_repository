defmodule CncfDashboardApi.SourceKeyProjectMonitorControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.SourceKeyProjectMonitor
  @valid_attrs %{source_pipeline_id: "some content", source_project_id: "some content", pipeline_release_type: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, source_key_project_monitor_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    source_key_project_monitor = Repo.insert! %SourceKeyProjectMonitor{}
    conn = get conn, source_key_project_monitor_path(conn, :show, source_key_project_monitor)
    assert json_response(conn, 200)["data"] == %{"id" => source_key_project_monitor.id,
      "source_project_id" => source_key_project_monitor.source_project_id,
      "source_pipeline_id" => source_key_project_monitor.source_pipeline_id,
      "pipeline_release_type" => source_key_project_monitor.pipeline_release_type}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, source_key_project_monitor_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, source_key_project_monitor_path(conn, :create), source_key_project_monitor: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(SourceKeyProjectMonitor, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, source_key_project_monitor_path(conn, :create), source_key_project_monitor: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    source_key_project_monitor = Repo.insert! %SourceKeyProjectMonitor{}
    conn = put conn, source_key_project_monitor_path(conn, :update, source_key_project_monitor), source_key_project_monitor: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(SourceKeyProjectMonitor, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    source_key_project_monitor = Repo.insert! %SourceKeyProjectMonitor{}
    conn = put conn, source_key_project_monitor_path(conn, :update, source_key_project_monitor), source_key_project_monitor: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    source_key_project_monitor = Repo.insert! %SourceKeyProjectMonitor{}
    conn = delete conn, source_key_project_monitor_path(conn, :delete, source_key_project_monitor)
    assert response(conn, 204)
    refute Repo.get(SourceKeyProjectMonitor, source_key_project_monitor.id)
  end
end
