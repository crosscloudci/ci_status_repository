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
      release_type: ref_monitor.release_type,
      project_id: ref_monitor.project_id,
      order: ref_monitor.order,
      pipeline_id: ref_monitor.pipeline_id}
  end
end
