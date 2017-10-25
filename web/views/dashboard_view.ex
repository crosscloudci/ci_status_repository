defmodule CncfDashboardApi.DashboardView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{dashboard: dashboard}) do
    %{dashboard: render_one(dashboard, CncfDashboardApi.DashboardView, "dashboard.json")}
  end
  def render("dashboard.json", %{dashboard: dashboard}) do
    dashboard["dashboard"]
  end

end
