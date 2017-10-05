defmodule CncfDashboardApi.SourceKeyProjectsView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{source_key_projects: source_key_projects}) do
    %{data: render_many(source_key_projects, CncfDashboardApi.SourceKeyProjectsView, "source_key_projects.json")}
  end

  def render("show.json", %{source_key_projects: source_key_projects}) do
    %{data: render_one(source_key_projects, CncfDashboardApi.SourceKeyProjectsView, "source_key_projects.json")}
  end

  def render("source_key_projects.json", %{source_key_projects: source_key_projects}) do
    %{id: source_key_projects.id,
      source_id: source_key_projects.source_id,
      new_id: source_key_projects.new_id,
      source_name: source_key_projects.source_name}
  end
end
