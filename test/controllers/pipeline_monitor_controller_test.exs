defmodule CncfDashboardApi.PipelineMonitorControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.PipelineMonitor
  @valid_attrs %{pipeline_id: 42, pipeline_type: "some content", project_id: 42, release_type: "some content", running: true}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, pipeline_monitor_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    pipeline_monitor = Repo.insert! %PipelineMonitor{}
    conn = get conn, pipeline_monitor_path(conn, :show, pipeline_monitor)
    assert json_response(conn, 200)["data"] == %{"id" => pipeline_monitor.id,
      "pipeline_id" => pipeline_monitor.pipeline_id,
      "running" => pipeline_monitor.running,
      "release_type" => pipeline_monitor.release_type,
      "pipeline_type" => pipeline_monitor.pipeline_type,
      "project_id" => pipeline_monitor.project_id}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, pipeline_monitor_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, pipeline_monitor_path(conn, :create), pipeline_monitor: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(PipelineMonitor, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, pipeline_monitor_path(conn, :create), pipeline_monitor: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    pipeline_monitor = Repo.insert! %PipelineMonitor{}
    conn = put conn, pipeline_monitor_path(conn, :update, pipeline_monitor), pipeline_monitor: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(PipelineMonitor, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    pipeline_monitor = Repo.insert! %PipelineMonitor{}
    conn = put conn, pipeline_monitor_path(conn, :update, pipeline_monitor), pipeline_monitor: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    pipeline_monitor = Repo.insert! %PipelineMonitor{}
    conn = delete conn, pipeline_monitor_path(conn, :delete, pipeline_monitor)
    assert response(conn, 204)
    refute Repo.get(PipelineMonitor, pipeline_monitor.id)
  end
end
