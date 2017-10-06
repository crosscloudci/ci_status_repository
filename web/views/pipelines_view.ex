defmodule CncfDashboardApi.PipelinesView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{pipelines: pipelines}) do
    %{data: render_many(pipelines, CncfDashboardApi.PipelinesView, "pipelines.json")}
  end

  def render("show.json", %{pipelines: pipelines}) do
    %{data: render_one(pipelines, CncfDashboardApi.PipelinesView, "pipelines.json")}
  end

  def render("pipelines.json", %{pipelines: pipelines}) do
    %{id: pipelines.id,
      ref: pipelines.ref,
      status: pipelines.status}
  end
end
