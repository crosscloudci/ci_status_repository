require IEx;
# require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.GitlabMonitorTest do
  use CncfDashboardApi.ChannelCase

  alias CncfDashboardApi.DashboardChannel

  import Ecto.Query
  import CncfDashboardApi.Factory
  # use EctoConditionals, repo: CncfDashboardApi.Repo
  use ExUnit.Case
  # use CncfDashboardApi.ModelCase
  
  test "target_project_exist?" do
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    project = Enum.find(project_map, fn(x) ->
      count = GitLabProxy.get_gitlab_pipelines(x["id"]) 
      |> Enum.count 
      count > 0
    end)
    pipeline_map = GitLabProxy.get_gitlab_pipelines(project["id"])
    pipeline = pipeline_map |> List.first 
    assert CncfDashboardApi.GitlabMonitor.target_project_exist?(project["name"], pipeline["id"] |> Integer.to_string) == false 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline( project["id"] |> Integer.to_string, pipeline["id"] |> Integer.to_string)
    assert CncfDashboardApi.GitlabMonitor.target_project_exist?(project["name"], pipeline["id"] |> Integer.to_string) == true
  end

  test "stable update: update_dashboard" do 
    skpm = insert(:source_key_project_monitor)
    # check insert 
    CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
    projects = insert(:project, %{ref_monitors: []})
    skpj = insert(:source_key_project, %{new_id: projects.id})
    CncfDashboardApi.GitlabMonitor.update_dashboard(skpm.id)
    pipeline_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineMonitor, :count, :id)  
    assert 1 = pipeline_monitor_count  
    assert_receive %Phoenix.Socket.Broadcast{ topic: "dashboard:*", 
      event: "new_cross_cloud_call", payload: %{reply: %{dashboard: dashboard}}}
    %{clouds: _, projects: projects} =dashboard
    head_badge = projects 
                 |> List.first 
                 |> Map.get(:pipelines) 
                 |> Enum.find(fn(x) -> x.release_type =~ "head" end) 
                 |> Map.get(:jobs) 
                 |> Enum.find(fn(x) -> x.order == 1 end)
    assert head_badge.status == "N/A"
    stable_badge = projects 
                 |> List.first 
                 |> Map.get(:pipelines) 
                 |> Enum.find(fn(x) -> x.release_type =~ "stable" end) 
                 |> Map.get(:jobs) 
                 |> Enum.find(fn(x) -> x.order == 1 end)
    assert (stable_badge.status == "running" || 
      stable_badge.status == "success" ||
      stable_badge.status == "failed"
    )

    pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
    assert 0 < pipeline_jobs_count  
    assert 0 < source_pipeline_jobs_count
  end

  test "stable update: upsert_pipeline_monitor" do 
    skpm = insert(:source_key_project_monitor)
    # check insert 
    CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
    projects = insert(:project, %{ref_monitors: []})
    skpj = insert(:source_key_project, %{new_id: projects.id})
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    pipeline_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineMonitor, :count, :id)  
    assert 1 = pipeline_monitor_count  
    assert_receive %Phoenix.Socket.Broadcast{ topic: "dashboard:*", 
      event: "new_cross_cloud_call", payload: %{reply: %{dashboard: dashboard}}}
    %{clouds: _, projects: projects} =dashboard
    head_badge = projects 
                 |> List.first 
                 |> Map.get(:pipelines) 
                 |> Enum.find(fn(x) -> x.release_type =~ "head" end) 
                 |> Map.get(:jobs) 
                 |> Enum.find(fn(x) -> x.order == 1 end)
    assert head_badge.status == "N/A"
    stable_badge = projects 
                 |> List.first 
                 |> Map.get(:pipelines) 
                 |> Enum.find(fn(x) -> x.release_type =~ "stable" end) 
                 |> Map.get(:jobs) 
                 |> Enum.find(fn(x) -> x.order == 1 end)
    assert (stable_badge.status == "running" || 
      stable_badge.status == "success" ||
      stable_badge.status == "failed"
    )

    pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
    assert 0 < pipeline_jobs_count  
    assert 0 < source_pipeline_jobs_count
  end

  @tag timeout: 300_000 
  test "head update: upsert_pipeline_monitor" do 
    skpm = insert(:head_source_key_project_monitor)
    # check insert 
    CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
    projects = insert(:project, %{ref_monitors: []})
    skpj = insert(:source_key_project, %{new_id: projects.id})
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    pipeline_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineMonitor, :count, :id)  
    assert 1 = pipeline_monitor_count  
    assert_receive %Phoenix.Socket.Broadcast{ topic: "dashboard:*", 
      event: "new_cross_cloud_call", payload: %{reply: %{dashboard: dashboard}}}
    %{clouds: _, projects: projects} =dashboard
    head_badge = projects 
                 |> List.first 
                 |> Map.get(:pipelines) 
                 |> Enum.find(fn(x) -> x.release_type =~ "head" end) 
                 |> Map.get(:jobs) 
                 |> Enum.find(fn(x) -> x.order == 1 end)
    assert (head_badge.status == "running" || 
      head_badge.status == "success" ||
      head_badge.status == "failed"
    )
    stable_badge = projects 
                 |> List.first 
                 |> Map.get(:pipelines) 
                 |> Enum.find(fn(x) -> x.release_type =~ "stable" end) 
                 |> Map.get(:jobs) 
                 |> Enum.find(fn(x) -> x.order == 1 end)
    assert stable_badge.status == "N/A"
    pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
    assert 0 < pipeline_jobs_count  
    assert 0 < source_pipeline_jobs_count
  end

  test "upsert_pipeline_monitor should not allow the same project and pipeline to monitor two different branches" do 
    skpm = insert(:source_key_project_monitor)
    # {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project)
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    skpm = insert(:source_key_project_monitor, %{pipeline_release_type: "head"})
    assert_raise RuntimeError, ~r/^You may not monitor the same project and pipeline for two different branches/, fn ->
      CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    end
  end

  test "Use upsert_ref_monitor to insert a ref monitor" do 
    # try with no ref_monitors
    project = insert(:project, %{ref_monitors: []})
    pipeline = project.pipelines |> List.first
    pipeline_monitor = insert(:pipeline_monitor, %{
      project_id: project.id,
      pipeline_id: pipeline.id})

    CncfDashboardApi.GitlabMonitor.upsert_gitlab_to_ref_monitor(project.id, pipeline.id)
    ref_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.RefMonitor, :count, :id)  
    assert 0 < ref_monitor_count  
    dbs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.DashboardBadgeStatus, :count, :id)  
    assert 0 < dbs_count

  end

  test "Use upsert_ref_monitor to update a ref monitor" do 
    # try with 1 ref_monitor
    project = insert(:project)
    pipeline = project.pipelines |> List.first
    pipeline_monitor = insert(:pipeline_monitor, %{
      project_id: project.id,
      pipeline_id: pipeline.id})

    CncfDashboardApi.GitlabMonitor.upsert_gitlab_to_ref_monitor(project.id, pipeline.id)
    ref_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.RefMonitor, :count, :id)  
    assert 0 < ref_monitor_count  
    dbs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.DashboardBadgeStatus, :count, :id)  
    assert 0 < dbs_count
  end



end
