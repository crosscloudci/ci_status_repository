defmodule CncfDashboardApi.PipelineMonitorView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{pipeline_monitor: pipeline_monitor}) do
    %{data: render_many(pipeline_monitor, CncfDashboardApi.PipelineMonitorView, "pipeline_monitor.json")}
  end

  def render("show.json", %{pipeline_monitor: pipeline_monitor}) do
    %{data: render_one(pipeline_monitor, CncfDashboardApi.PipelineMonitorView, "pipeline_monitor.json")}
  end

  def render("pipeline_monitor.json", %{pipeline_monitor: pipeline_monitor}) do
    %{id: pipeline_monitor.id,
      pipeline_id: pipeline_monitor.pipeline_id,
      running: pipeline_monitor.running,
      release_type: pipeline_monitor.release_type,
      pipeline_type: pipeline_monitor.pipeline_type,
      project_id: pipeline_monitor.project_id}
  end
end
