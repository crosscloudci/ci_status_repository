require IEx;
# require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.GitlabMonitorTest do
  import Ecto.Query
  import CncfDashboardApi.Factory
  # use EctoConditionals, repo: CncfDashboardApi.Repo
  use ExUnit.Case
  use CncfDashboardApi.ModelCase


  @tag :wip
  test "upsert_pipeline_monitor" do 
    skpm = insert(:source_key_project_monitor)
    # check insert 
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    pipeline_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineMonitor, :count, :id)  
    # source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
    assert 1 = pipeline_monitor_count  
    # assert 1 < project_count  
    # assert 1 < source_project_count
    # # check update -- should not increase
    # {:ok, upsert, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    # assert project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    # assert source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
  end
  @tag :wip
  test "is_deploy_pipeline_type" do 
    project = insert(:project)
    assert CncfDashboardApi.GitlabMonitor.is_deploy_pipeline_type(project.id) == false
    cross_cloud = insert(:project, %{name: "cross-cloud"})
    assert CncfDashboardApi.GitlabMonitor.is_deploy_pipeline_type(cross_cloud.id) == true 
  end
end
