defmodule CncfDashboardApi.RefMonitorView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{ref_monitor: ref_monitor}) do
    %{data: render_many(ref_monitor, CncfDashboardApi.RefMonitorView, "ref_monitor.json")}
  end

  def render("show.json", %{ref_monitor: ref_monitor}) do
    %{data: render_one(ref_monitor, CncfDashboardApi.RefMonitorView, "ref_monitor.json")}
  end

  def render("ref_monitor.json", %{ref_monitor: ref_monitor}) do
    %{id: ref_monitor.id,
      ref: ref_monitor.ref,
      status: ref_monitor.status,
      sha: ref_monitor.sha,
      head_commit: ref_monitor.sha,
      release_type: ref_monitor.release_type,
      kubernetes_release_type: ref_monitor.kubernetes_release_type,
      arch: ref_monitor.arch,
      test_env: ref_monitor.test_env,
      stable_tag: ref_monitor.release_type,
      project_id: ref_monitor.project_id,
      order: ref_monitor.order,
      pipeline_id: ref_monitor.id,
      jobs: render_many(ref_monitor.dashboard_badge_statuses, CncfDashboardApi.DashboardBadgeStatusView, "dashboard_badge_status.json"),
    }
      # badges: render_many(ref_monitor.dashboard_badge_statuses, CncfDashboardApi.DashboardBadgeStatusView, "dashboard_badge_status.json"),
  end
end
