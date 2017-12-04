defmodule CncfDashboardApi.SourceKeyPipelinesControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.SourceKeyPipelines
  @valid_attrs %{new_id: 42, source_id: "some content", source_name: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} = config do
    signed_conn = Guardian.Plug.api_sign_in(conn, nil)
    {:ok, conn: signed_conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, source_key_pipelines_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    source_key_pipelines = Repo.insert! %SourceKeyPipelines{}
    conn = get conn, source_key_pipelines_path(conn, :show, source_key_pipelines)
    assert json_response(conn, 200)["data"] == %{"id" => source_key_pipelines.id,
      "source_id" => source_key_pipelines.source_id,
      "new_id" => source_key_pipelines.new_id,
      "source_name" => source_key_pipelines.source_name}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, source_key_pipelines_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, source_key_pipelines_path(conn, :create), source_key_pipelines: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(SourceKeyPipelines, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, source_key_pipelines_path(conn, :create), source_key_pipelines: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    source_key_pipelines = Repo.insert! %SourceKeyPipelines{}
    conn = put conn, source_key_pipelines_path(conn, :update, source_key_pipelines), source_key_pipelines: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(SourceKeyPipelines, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    source_key_pipelines = Repo.insert! %SourceKeyPipelines{}
    conn = put conn, source_key_pipelines_path(conn, :update, source_key_pipelines), source_key_pipelines: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    source_key_pipelines = Repo.insert! %SourceKeyPipelines{}
    conn = delete conn, source_key_pipelines_path(conn, :delete, source_key_pipelines)
    assert response(conn, 204)
    refute Repo.get(SourceKeyPipelines, source_key_pipelines.id)
  end
end
