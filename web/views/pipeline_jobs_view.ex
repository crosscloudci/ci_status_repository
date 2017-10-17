defmodule CncfDashboardApi.PipelineJobsView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{pipeline_jobs: pipeline_jobs}) do
    %{data: render_many(pipeline_jobs, CncfDashboardApi.PipelineJobsView, "pipeline_jobs.json")}
  end

  def render("show.json", %{pipeline_jobs: pipeline_jobs}) do
    %{data: render_one(pipeline_jobs, CncfDashboardApi.PipelineJobsView, "pipeline_jobs.json")}
  end

  def render("pipeline_jobs.json", %{pipeline_jobs: pipeline_jobs}) do
    %{id: pipeline_jobs.id,
      name: pipeline_jobs.name,
      status: pipeline_jobs.status,
      ref: pipeline_jobs.ref,
      pipeline_source_id: pipeline_jobs.pipeline_source_id}
  end
end
