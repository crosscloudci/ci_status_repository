defmodule CncfDashboardApi.CloudsControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.Clouds
  @valid_attrs %{cloud_name: "some content", display_name: "hi", order: 1}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, clouds_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  @tag :wip
  test "shows chosen resource", %{conn: conn} do
    clouds = Repo.insert! %Clouds{}
    conn = get conn, clouds_path(conn, :show, clouds)
    assert json_response(conn, 200)["data"] == %{"id" => clouds.id,
      "cloud_id" => clouds.id,
      "order" => clouds.order,
      "cloud_name" => clouds.cloud_name}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, clouds_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, clouds_path(conn, :create), clouds: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Clouds, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, clouds_path(conn, :create), clouds: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    clouds = Repo.insert! %Clouds{}
    conn = put conn, clouds_path(conn, :update, clouds), clouds: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Clouds, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    clouds = Repo.insert! %Clouds{}
    conn = put conn, clouds_path(conn, :update, clouds), clouds: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    clouds = Repo.insert! %Clouds{}
    conn = delete conn, clouds_path(conn, :delete, clouds)
    assert response(conn, 204)
    refute Repo.get(Clouds, clouds.id)
  end
end
