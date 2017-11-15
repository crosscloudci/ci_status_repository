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
      status: dashboard_badge_status.status,
      cloud_id: dashboard_badge_status.cloud_id,
      ref_monitor_id: dashboard_badge_status.ref_monitor_id,
      order: dashboard_badge_status.order}
  end
end
