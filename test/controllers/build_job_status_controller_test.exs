defmodule CncfDashboardApi.BuildJobStatusControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.BuildJobStatus
  @valid_attrs %{pipeline_id: 42, pipeline_monitor_id: 42, status: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, build_job_status_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    build_job_status = Repo.insert! %BuildJobStatus{}
    conn = get conn, build_job_status_path(conn, :show, build_job_status)
    assert json_response(conn, 200)["data"] == %{"id" => build_job_status.id,
      "status" => build_job_status.status,
      "pipeline_id" => build_job_status.pipeline_id,
      "pipeline_monitor_id" => build_job_status.pipeline_monitor_id}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, build_job_status_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, build_job_status_path(conn, :create), build_job_status: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(BuildJobStatus, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, build_job_status_path(conn, :create), build_job_status: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    build_job_status = Repo.insert! %BuildJobStatus{}
    conn = put conn, build_job_status_path(conn, :update, build_job_status), build_job_status: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(BuildJobStatus, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    build_job_status = Repo.insert! %BuildJobStatus{}
    conn = put conn, build_job_status_path(conn, :update, build_job_status), build_job_status: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    build_job_status = Repo.insert! %BuildJobStatus{}
    conn = delete conn, build_job_status_path(conn, :delete, build_job_status)
    assert response(conn, 204)
    refute Repo.get(BuildJobStatus, build_job_status.id)
  end
end
