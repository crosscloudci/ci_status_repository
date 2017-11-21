require IEx;
defimpl Poison.Encoder, for: Tuple do
    def encode(tuple, options) do
          tuple
          |> Tuple.to_list
          |> Poison.encode!
        end
end
defmodule CncfDashboardApi.DashboardController do
  use CncfDashboardApi.Web, :controller
  use EctoConditionals, repo: CncfDashboardApi.Repo

  alias CncfDashboardApi.Dashboard

  def index(conn, _params) do
    yml = System.get_env("GITLAB_CI_YML")
    {d_found, d_record} = %CncfDashboardApi.Dashboard{gitlab_ci_yml: yml } |> find_by([:gitlab_ci_yml])
    
    cloud_list = CncfDashboardApi.Repo.all(from cd1 in CncfDashboardApi.Clouds, 
                                           where: cd1.active == true,
                                           order_by: [cd1.order]) 
    
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: ref_monitors in assoc(projects, :ref_monitors),
                                         left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                                         left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                                         where: projects.active == true,
                                         order_by: [projects.order, ref_monitors.order, dashboard_badge_statuses.order], 
                                         preload: [ref_monitors: 
                                                   {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                                     dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                                   }] )

    with_cloud = %{"dashboard" => d_record, "clouds" => cloud_list, "projects" => projects} 
    render(conn, "index.json", dashboard: with_cloud)
  end

end
