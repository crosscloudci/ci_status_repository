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
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    # project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    # source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
    # assert 1 < upsert_count  
    # assert 1 < project_count  
    # assert 1 < source_project_count
    # # check update -- should not increase
    # {:ok, upsert, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    # assert project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    # assert source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
  end
end
