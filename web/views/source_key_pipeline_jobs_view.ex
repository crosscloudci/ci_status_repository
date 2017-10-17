defmodule CncfDashboardApi.SourceKeyPipelineJobsView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{source_key_pipeline_jobs: source_key_pipeline_jobs}) do
    %{data: render_many(source_key_pipeline_jobs, CncfDashboardApi.SourceKeyPipelineJobsView, "source_key_pipeline_jobs.json")}
  end

  def render("show.json", %{source_key_pipeline_jobs: source_key_pipeline_jobs}) do
    %{data: render_one(source_key_pipeline_jobs, CncfDashboardApi.SourceKeyPipelineJobsView, "source_key_pipeline_jobs.json")}
  end

  def render("source_key_pipeline_jobs.json", %{source_key_pipeline_jobs: source_key_pipeline_jobs}) do
    %{id: source_key_pipeline_jobs.id,
      source_id: source_key_pipeline_jobs.source_id,
      new_id: source_key_pipeline_jobs.new_id,
      source_name: source_key_pipeline_jobs.source_name}
  end
end
