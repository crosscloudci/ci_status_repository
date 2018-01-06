require IEx;
# require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.GitlabMonitor.PipelineTest do
  use CncfDashboardApi.ChannelCase

  alias CncfDashboardApi.DashboardChannel

  import Ecto.Query
  import CncfDashboardApi.Factory
  use ExUnit.Case
  

  test "is_deploy_pipeline_type" do 
    project = insert(:project)
    assert CncfDashboardApi.GitlabMonitor.Pipeline.is_deploy_pipeline_type(project.id) == false
    cross_cloud = insert(:project, %{name: "cross-cloud"})
    assert CncfDashboardApi.GitlabMonitor.Pipeline.is_deploy_pipeline_type(cross_cloud.id) == true 
  end
end
