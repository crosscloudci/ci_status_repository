require IEx;
defmodule CncfDashboardApi.DashboardView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{dashboard: dashboard}) do
    %{dashboard: render_one(dashboard, CncfDashboardApi.DashboardView, "dashboard.json")}
  end
  def render("dashboard.json", %{dashboard: dashboard}) do
    %{
      clouds: render_many(dashboard["clouds"], CncfDashboardApi.CloudsView, "clouds.json"),
      projects: render_many(dashboard["projects"], CncfDashboardApi.ProjectsView, "projects.json"),
    }
  end

end
