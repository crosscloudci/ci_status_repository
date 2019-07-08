require IEx;
defmodule CncfDashboardApi.DashboardView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{dashboard: dashboard}) do
    %{dashboard: render_one(dashboard, CncfDashboardApi.DashboardView, "dashboard.json")}
  end
  def render("dashboard.json", %{dashboard: dashboard}) do
      kubernetes_release_types = ["stable", "head"]
      kubernetes_refs = ["v1.13.0", "03a6d0bf5439c0ac10e929d8aac1cba9517be744"]
    %{
      last_check: if(dashboard["dashboard"] && Timex.is_valid?(dashboard["dashboard"].last_check), do: Timex.format(dashboard["dashboard"].last_check, "{relative}", :relative) |> elem(1)),
      last_check_dt: if(dashboard["dashboard"] && Timex.is_valid?(dashboard["dashboard"].last_check), do: dashboard["dashboard"].last_check),
      clouds: render_many(dashboard["clouds"], CncfDashboardApi.CloudsView, "clouds.json"),
      projects: render_many(dashboard["projects"], CncfDashboardApi.ProjectsView, "projects.json"),
      kubernetes_release_types: kubernetes_release_types,
      kubernetes_refs: kubernetes_refs, 
      test_env: kubernetes_release_types, 
      cncf_relations: dashboard["cncf_relations"], 
      archs: ["amd64", "arm64"],
    }
  end

end
