require IEx;
# require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.GitlabMonitor.DashboardTest do
  use CncfDashboardApi.ChannelCase
  alias CncfDashboardApi.DashboardChannel
  import Ecto.Query
  import CncfDashboardApi.Factory
  use ExUnit.Case
  

  test "new_n_a_ref_monitor" do 
    project = insert(:project, %{ref_monitors: [], pipelines: 
      [build(:pipeline, %{pipeline_jobs:
        [build(:pipeline_job, %{name: "App-Deploy", status: "failed"}),
         build(:pipeline_job, %{name: "e2e", status: "running"}),
        ]
      })]} )
    CncfDashboardApi.GitlabMigrations.upsert_clouds()

    new_ref =  CncfDashboardApi.GitlabMonitor.Dashboard.new_n_a_ref_monitor(project.id, "stable", 1)
    r_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.RefMonitor, :count, :id)  
    b_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.DashboardBadgeStatus, :count, :id)  
    assert 0 < r_count  
    assert 0 < b_count  
  end

  test "initialize_ref_monitor" do 
    project = insert(:project, %{ref_monitors: []})
    CncfDashboardApi.GitlabMonitor.Dashboard.initialize_ref_monitor(project.id)
    ref_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.RefMonitor, :count, :id)  
    assert 2 = ref_monitor_count  
    dbs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.DashboardBadgeStatus, :count, :id)  
    assert 4 = dbs_count
  end

end
