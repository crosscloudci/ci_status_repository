defmodule CncfDashboardApi.DashboardBadgeStatusControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.DashboardBadgeStatus
  @valid_attrs %{cloud_id: 42, order: 42, ref_monitor_id: 42, status: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, dashboard_badge_status_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    dashboard_badge_status = Repo.insert! %DashboardBadgeStatus{}
    conn = get conn, dashboard_badge_status_path(conn, :show, dashboard_badge_status)
    assert json_response(conn, 200)["data"] == %{"id" => dashboard_badge_status.id,
      "status" => dashboard_badge_status.status,
      "cloud_id" => dashboard_badge_status.cloud_id,
      "job_id" => dashboard_badge_status.id, "name" => "N/A", "pipeline_id" => nil, "project_id" => nil, "ref" => "N/A", "url" => nil,
      "order" => dashboard_badge_status.order}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, dashboard_badge_status_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, dashboard_badge_status_path(conn, :create), dashboard_badge_status: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(DashboardBadgeStatus, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, dashboard_badge_status_path(conn, :create), dashboard_badge_status: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    dashboard_badge_status = Repo.insert! %DashboardBadgeStatus{}
    conn = put conn, dashboard_badge_status_path(conn, :update, dashboard_badge_status), dashboard_badge_status: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(DashboardBadgeStatus, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    dashboard_badge_status = Repo.insert! %DashboardBadgeStatus{}
    conn = put conn, dashboard_badge_status_path(conn, :update, dashboard_badge_status), dashboard_badge_status: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    dashboard_badge_status = Repo.insert! %DashboardBadgeStatus{}
    conn = delete conn, dashboard_badge_status_path(conn, :delete, dashboard_badge_status)
    assert response(conn, 204)
    refute Repo.get(DashboardBadgeStatus, dashboard_badge_status.id)
  end
end
