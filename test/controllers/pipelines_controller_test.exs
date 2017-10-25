defmodule CncfDashboardApi.DashboardControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.Dashboard
  @valid_attrs %{ref: "some content", status: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, dashboard_path(conn, :index)
    cloud_list = json_response(conn, 200)["dashboard"]["clouds"] |> List.first
    assert  cloud_list["cloud_id"] == 1 
  end

end
