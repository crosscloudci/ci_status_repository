require IEx;
defmodule CncfDashboardApi.DashboardView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{dashboard: dashboard}) do
    %{dashboard: render_one(dashboard, CncfDashboardApi.DashboardView, "dashboard.json")}
  end
  def render("dashboard.json", %{dashboard: dashboard}) do
    %{
      last_check: if(dashboard["dashboard"] && Timex.is_valid?(dashboard["dashboard"].last_check), do: Timex.format(dashboard["dashboard"].last_check, "{relative}", :relative) |> elem(1)),
      last_check_dt: if(dashboard["dashboard"] && Timex.is_valid?(dashboard["dashboard"].last_check), do: dashboard["dashboard"].last_check),
      clouds: render_many(dashboard["clouds"], CncfDashboardApi.CloudsView, "clouds.json"),
      projects: render_many(dashboard["projects"], CncfDashboardApi.ProjectsView, "projects.json"),
    }
  end

end
