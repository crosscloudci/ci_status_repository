require IEx;
defmodule CncfDashboardApi.PipelinesView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{pipelines: pipelines}) do
    %{data: render_many(pipelines, CncfDashboardApi.PipelinesView, "pipelines.json")}
  end

  def render("show.json", %{pipelines: pipelines}) do
    %{data: render_one(pipelines, CncfDashboardApi.PipelinesView, "pipelines.json")}
  end

  def render("pipelines.json", %{pipelines: pipelines}) do
    # call a render_many for each pipeline
    %{id: pipelines.id,
      pipeline_id: pipelines.id,
      project_id: pipelines.project_id,
      status: pipelines.status,
      stable_tag: pipelines.release_type,
      head_commit: pipelines.sha,
      ref: pipelines.ref,
      jobs: render_many(pipelines.pipeline_jobs, CncfDashboardApi.PipelineJobsView, "pipeline_jobs.json"),
      }
  end

  # "pipelines":[
  #   {
  #     "pipeline_id":1,
  #     "project_id":2,
  #     "status":"successful",
  #     "stable_tag":"release",
  #     "head_commit":"2342342342343243sdfsdfsdfs",
  #     "jobs":[
  #       {
  #         "pipeline_id":1,
  #         "project_id":2,
  #         "job_id":26,
  #         "cloud_id":1,
  #         "status":"fail"
  #       },
  def render("pipelines_with_jobs.json", %{pipelines: pipelines}) do
    # call a render_many for each pipeline
    %{id: pipelines.id,
      ref: pipelines.ref,
      # jobs: render_many(pipeline_jobs, CncfDashboardApi.PipelinesView, "pipelines.json")
      jobs: render_many(pipelines.pipeline_jobs, CncfDashboardApi.PipelinesView, "pipeline_jobs.json"),
      status: pipelines.status}
  end
end
