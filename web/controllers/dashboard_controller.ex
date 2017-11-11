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
                                           select: %{id: cd1.id, cloud_id: cd1.id, 
                                             name: cd1.cloud_name, cloud_name: cd1.cloud_name}) 
    projects = CncfDashboardApi.Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: pipelines in assoc(projects, :pipelines),
                                         left_join: pipeline_jobs in assoc(pipelines, :pipeline_jobs),
                                         left_join: cloud in assoc(pipeline_jobs, :cloud),
                                         preload: [pipelines: 
                                                   {pipelines, pipeline_jobs: pipeline_jobs, 
                                                     pipeline_jobs: {pipeline_jobs, cloud: cloud },
                                                   }] )

    with_cloud = %{"clouds" => cloud_list, "projects" => projects} 
    render(conn, "index.json", dashboard: with_cloud)
  end

end
