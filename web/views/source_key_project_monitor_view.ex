defmodule CncfDashboardApi.SourceKeyProjectMonitorView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{source_key_project_monitor: source_key_project_monitor}) do
    %{data: render_many(source_key_project_monitor, CncfDashboardApi.SourceKeyProjectMonitorView, "source_key_project_monitor.json")}
  end

  def render("show.json", %{source_key_project_monitor: source_key_project_monitor}) do
    %{data: render_one(source_key_project_monitor, CncfDashboardApi.SourceKeyProjectMonitorView, "source_key_project_monitor.json")}
  end

  def render("source_key_project_monitor.json", %{source_key_project_monitor: source_key_project_monitor}) do
    %{id: source_key_project_monitor.id,
      source_project_id: source_key_project_monitor.source_project_id,
      source_pipeline_id: source_key_project_monitor.source_pipeline_id,
      pipeline_release_type: source_key_project_monitor.pipeline_release_type }
  end
end
