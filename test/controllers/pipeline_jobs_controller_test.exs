require IEx;
defmodule CncfDashboardApi.PipelineJobsControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.PipelineJobs
                # "jobs":[
                #   {
                #     "pipeline_id":1,
                #     "project_id":1,
                #     "job_id":23,
                #     "cloud_id":1,
                #     "status":"fail"
                #   },
  @valid_attrs %{pipeline_id: 1, project_id: 1, job_id: 23, cloud_id: 1, name: "some content", ref: "some content", status: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @tag :wip
  test "lists all entries on index", %{conn: conn} do
    conn = get conn, pipeline_jobs_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  @tag :wip
  test "shows chosen resource", %{conn: conn} do
    pipeline_jobs = Repo.insert! %PipelineJobs{}
    conn = get conn, pipeline_jobs_path(conn, :show, pipeline_jobs)
    assert json_response(conn, 200)["data"] == %{"id" => pipeline_jobs.id, 
      "name" => pipeline_jobs.name, 
      "status" => pipeline_jobs.status, 
      "ref" => pipeline_jobs.ref, 
      "cloud_id" => pipeline_jobs.cloud_id, 
      "job_id" => pipeline_jobs.id, 
      "pipeline_id" => pipeline_jobs.pipeline_id, 
      "project_id" => pipeline_jobs.project_id} 
  end

  @tag :wip
  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, pipeline_jobs_path(conn, :show, -1)
    end
  end

  @tag :wip
  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, pipeline_jobs_path(conn, :create), pipeline_jobs: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    # using specialized json
    assert Repo.get_by(PipelineJobs, @valid_attrs |> Map.delete(:job_id) )
  end

  @tag :wip
  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, pipeline_jobs_path(conn, :create), pipeline_jobs: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  @tag :wip
  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    pipeline_jobs = Repo.insert! %PipelineJobs{}
    conn = put conn, pipeline_jobs_path(conn, :update, pipeline_jobs), pipeline_jobs: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(PipelineJobs, @valid_attrs |> Map.delete(:job_id))
  end

  @tag :wip
  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    pipeline_jobs = Repo.insert! %PipelineJobs{}
    conn = put conn, pipeline_jobs_path(conn, :update, pipeline_jobs), pipeline_jobs: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  @tag :wip
  test "deletes chosen resource", %{conn: conn} do
    pipeline_jobs = Repo.insert! %PipelineJobs{}
    conn = delete conn, pipeline_jobs_path(conn, :delete, pipeline_jobs)
    assert response(conn, 204)
    refute Repo.get(PipelineJobs, pipeline_jobs.id)
  end
end
