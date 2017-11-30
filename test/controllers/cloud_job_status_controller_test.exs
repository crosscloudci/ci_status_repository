defmodule CncfDashboardApi.CloudJobStatusControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.CloudJobStatus
  @valid_attrs %{cloud_id: 42, pipeline_id: 42, status: "some content"}
  @invalid_attrs %{}

  # setup %{conn: conn} do
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end
  setup %{conn: conn} = config do
    signed_conn = Guardian.Plug.api_sign_in(conn, nil)
    {:ok, conn: signed_conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, cloud_job_status_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    cloud_job_status = Repo.insert! %CloudJobStatus{}
    conn = get conn, cloud_job_status_path(conn, :show, cloud_job_status)
    assert json_response(conn, 200)["data"] == %{"id" => cloud_job_status.id,
      "cloud_id" => cloud_job_status.cloud_id,
      "status" => cloud_job_status.status,
      "pipeline_id" => cloud_job_status.pipeline_id}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, cloud_job_status_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, cloud_job_status_path(conn, :create), cloud_job_status: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(CloudJobStatus, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, cloud_job_status_path(conn, :create), cloud_job_status: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    cloud_job_status = Repo.insert! %CloudJobStatus{}
    conn = put conn, cloud_job_status_path(conn, :update, cloud_job_status), cloud_job_status: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(CloudJobStatus, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    cloud_job_status = Repo.insert! %CloudJobStatus{}
    conn = put conn, cloud_job_status_path(conn, :update, cloud_job_status), cloud_job_status: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    cloud_job_status = Repo.insert! %CloudJobStatus{}
    conn = delete conn, cloud_job_status_path(conn, :delete, cloud_job_status)
    assert response(conn, 204)
    refute Repo.get(CloudJobStatus, cloud_job_status.id)
  end
end
