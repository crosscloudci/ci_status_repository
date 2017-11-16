defmodule CncfDashboardApi.ProjectsView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{projects: projects}) do
    %{data: render_many(projects, CncfDashboardApi.ProjectsView, "projects.json")}
  end

  def render("show.json", %{projects: projects}) do
    %{data: render_one(projects, CncfDashboardApi.ProjectsView, "projects.json")}
  end

  def render("projects.json", %{projects: projects}) do
    %{id: projects.id,
      name: projects.name,
      project_id: projects.id,
      title: projects.name,
      caption: projects.sub_title,
      url: projects.project_url,
      icon: projects.logo_url,
      display_name: projects.display_name,
      sub_title: projects.sub_title,
      ssh_url_to_repo: projects.ssh_url_to_repo,
      pipelines: render_many(projects.ref_monitors, CncfDashboardApi.RefMonitorView, "ref_monitor.json"),
      # ref_monitors: render_many(projects.ref_monitor, CncfDashboardApi.RefMonitor, "ref_monitor.json"),
      http_url_to_repo: projects.http_url_to_repo}
  end
end
