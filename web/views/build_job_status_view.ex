defmodule CncfDashboardApi.BuildJobStatusView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{build_job_status: build_job_status}) do
    %{data: render_many(build_job_status, CncfDashboardApi.BuildJobStatusView, "build_job_status.json")}
  end

  def render("show.json", %{build_job_status: build_job_status}) do
    %{data: render_one(build_job_status, CncfDashboardApi.BuildJobStatusView, "build_job_status.json")}
  end

  def render("build_job_status.json", %{build_job_status: build_job_status}) do
    %{id: build_job_status.id,
      status: build_job_status.status,
      pipeline_id: build_job_status.pipeline_id,
      pipeline_monitor_id: build_job_status.pipeline_monitor_id}
  end
end
