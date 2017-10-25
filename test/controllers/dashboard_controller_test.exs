defmodule CncfDashboardApi.PipelinesControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.Pipelines
  @valid_attrs %{ref: "some content", status: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, pipelines_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    pipelines = Repo.insert! %Pipelines{}
    conn = get conn, pipelines_path(conn, :show, pipelines)
    assert json_response(conn, 200)["data"] == %{"id" => pipelines.id,
      "ref" => pipelines.ref,
      "status" => pipelines.status}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, pipelines_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, pipelines_path(conn, :create), pipelines: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Pipelines, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, pipelines_path(conn, :create), pipelines: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    pipelines = Repo.insert! %Pipelines{}
    conn = put conn, pipelines_path(conn, :update, pipelines), pipelines: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Pipelines, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    pipelines = Repo.insert! %Pipelines{}
    conn = put conn, pipelines_path(conn, :update, pipelines), pipelines: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    pipelines = Repo.insert! %Pipelines{}
    conn = delete conn, pipelines_path(conn, :delete, pipelines)
    assert response(conn, 204)
    refute Repo.get(Pipelines, pipelines.id)
  end
end
