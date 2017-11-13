defmodule CncfDashboardApi.CloudJobStatusView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{cloud_job_status: cloud_job_status}) do
    %{data: render_many(cloud_job_status, CncfDashboardApi.CloudJobStatusView, "cloud_job_status.json")}
  end

  def render("show.json", %{cloud_job_status: cloud_job_status}) do
    %{data: render_one(cloud_job_status, CncfDashboardApi.CloudJobStatusView, "cloud_job_status.json")}
  end

  def render("cloud_job_status.json", %{cloud_job_status: cloud_job_status}) do
    %{id: cloud_job_status.id,
      cloud_id: cloud_job_status.cloud_id,
      status: cloud_job_status.status,
      pipeline_id: cloud_job_status.pipeline_id}
  end
end
