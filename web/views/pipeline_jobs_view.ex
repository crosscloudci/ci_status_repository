defmodule CncfDashboardApi.PipelineJobsView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{pipeline_jobs: pipeline_jobs}) do
    %{data: render_many(pipeline_jobs, CncfDashboardApi.PipelineJobsView, "pipeline_jobs.json")}
  end

  def render("show.json", %{pipeline_jobs: pipeline_jobs}) do
    %{data: render_one(pipeline_jobs, CncfDashboardApi.PipelineJobsView, "pipeline_jobs.json")}
  end

  # "jobs":[
  #   {
  #     "pipeline_id":1,
  #     "project_id":2,
  #     "job_id":26,
  #     "cloud_id":1,
  #     "status":"fail"
  #   },
  def render("pipeline_jobs.json", %{pipeline_jobs: pipeline_jobs}) do
    %{id: pipeline_jobs.id,
      pipeline_id: pipeline_jobs.pipeline_id,
      project_id: pipeline_jobs.project_id,
      job_id: pipeline_jobs.id,
      cloud_id: pipeline_jobs.cloud_id,
      name: pipeline_jobs.name,
      status: pipeline_jobs.status,
      ref: pipeline_jobs.ref }
  end
end
