defmodule CncfDashboardApi.SourceKeyPipelinesView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{source_key_pipelines: source_key_pipelines}) do
    %{data: render_many(source_key_pipelines, CncfDashboardApi.SourceKeyPipelinesView, "source_key_pipelines.json")}
  end

  def render("show.json", %{source_key_pipelines: source_key_pipelines}) do
    %{data: render_one(source_key_pipelines, CncfDashboardApi.SourceKeyPipelinesView, "source_key_pipelines.json")}
  end

  def render("source_key_pipelines.json", %{source_key_pipelines: source_key_pipelines}) do
    %{id: source_key_pipelines.id,
      source_id: source_key_pipelines.source_id,
      new_id: source_key_pipelines.new_id,
      source_name: source_key_pipelines.source_name}
  end
end
