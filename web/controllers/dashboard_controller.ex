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

  alias CncfDashboardApi.Dashboard

  def index(conn, _params) do
    cloud_list = CncfDashboardApi.Repo.all(from cd1 in CncfDashboardApi.Clouds, 
                                           where: cd1.active == true,
                                           select: %{id: cd1.id, cloud_id: cd1.id, 
                                             name: cd1.cloud_name, cloud_name: cd1.cloud_name}) 
    
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: ref_monitors in assoc(projects, :ref_monitors),
                                         left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                                         left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                                         where: projects.active == true,
                                         order_by: [projects.order,dashboard_badge_statuses.order], 
                                         preload: [ref_monitors: 
                                                   {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                                     dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                                   }] )

    with_cloud = %{"clouds" => cloud_list, "projects" => projects} 
    render(conn, "index.json", dashboard: with_cloud)
  end

end
