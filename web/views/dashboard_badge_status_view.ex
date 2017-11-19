defmodule CncfDashboardApi.DashboardBadgeStatusView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{dashboard_badge_status: dashboard_badge_status}) do
    %{data: render_many(dashboard_badge_status, CncfDashboardApi.DashboardBadgeStatusView, "dashboard_badge_status.json")}
  end

  def render("show.json", %{dashboard_badge_status: dashboard_badge_status}) do
    %{data: render_one(dashboard_badge_status, CncfDashboardApi.DashboardBadgeStatusView, "dashboard_badge_status.json")}
  end

  def render("dashboard_badge_status.json", %{dashboard_badge_status: dashboard_badge_status}) do
    %{id: dashboard_badge_status.id,
      pipeline_id: dashboard_badge_status.ref_monitor_id,
      # project_id: dashboard_badge_status.ref_monitor.project.id,
      # belongs_to preload doesn't work
      project_id: (rm1 = CncfDashboardApi.Repo.get_by(CncfDashboardApi.RefMonitor, id: dashboard_badge_status.ref_monitor_id) |> CncfDashboardApi.Repo.preload(:project) ; rm1 && rm1.project.id),
      job_id: dashboard_badge_status.id,
      cloud_id: dashboard_badge_status.cloud_id,
      name: "N/A",
      status: dashboard_badge_status.status,
      # ref_monitor_id: dashboard_badge_status.ref_monitor_id,
      ref: "N/A",
      url: dashboard_badge_status.url,
      order: dashboard_badge_status.order}
  end
end
