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
  
  # test "upsert_pipeline_monitor", %{socket: socket} do 
  test "upsert_pipeline_monitor" do 
    skpm = insert(:source_key_project_monitor)
    # check insert 
    CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
    {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project)
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    pipeline_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineMonitor, :count, :id)  
    # source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
    assert 1 = pipeline_monitor_count  
    assert_receive %Phoenix.Socket.Broadcast{ topic: "dashboard:*", 
      event: "new_cross_cloud_call", payload: %{reply: %{dashboard: dashboard}}}

    pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
    assert 0 < pipeline_jobs_count  
    assert 0 < source_pipeline_jobs_count
  end

  test "upsert_pipeline_monitor should not allow the same project and pipeline to monitor two different branches" do 
    skpm = insert(:source_key_project_monitor)
    {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project)
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    skpm = insert(:source_key_project_monitor, %{pipeline_release_type: "head"})
    assert_raise RuntimeError, ~r/^You may not monitor the same project and pipeline for two different branches/, fn ->
      CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    end
  end

  test "is_deploy_pipeline_type" do 
    project = insert(:project)
    assert CncfDashboardApi.GitlabMonitor.is_deploy_pipeline_type(project.id) == false
    cross_cloud = insert(:project, %{name: "cross-cloud"})
    assert CncfDashboardApi.GitlabMonitor.is_deploy_pipeline_type(cross_cloud.id) == true 
  end

  test "Use upsert_ref_monitor to insert a ref monitor" do 

    # try with no ref_monitors
    project = insert(:project, %{ref_monitors: []})
    pipeline = project.pipelines |> List.first
    pipeline_monitor = insert(:pipeline_monitor, %{
      project_id: project.id,
      pipeline_id: pipeline.id})

    CncfDashboardApi.GitlabMonitor.upsert_ref_monitor(project.id, pipeline.id)
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

    CncfDashboardApi.GitlabMonitor.upsert_ref_monitor(project.id, pipeline.id)
    ref_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.RefMonitor, :count, :id)  
    assert 0 < ref_monitor_count  
    dbs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.DashboardBadgeStatus, :count, :id)  
    assert 0 < dbs_count
  end

  test "initialize_ref_monitor" do 
    project = insert(:project, %{ref_monitors: []})
    CncfDashboardApi.GitlabMonitor.initialize_ref_monitor(project.id)
    ref_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.RefMonitor, :count, :id)  
    assert 2 = ref_monitor_count  
    dbs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.DashboardBadgeStatus, :count, :id)  
    assert 4 = dbs_count
  end

  @tag :wip
  test "compile_url" do 
    project = insert(:project, %{pipelines: 
      [build(:pipeline, %{pipeline_jobs:
        [build(:pipeline_job, %{name: "compile"}) ]})]} )
    pipeline = project.pipelines |> List.first
    pipeline_job = pipeline.pipeline_jobs |> List.first
    url = CncfDashboardApi.GitlabMonitor.compile_url(pipeline.id)
    temp_url = "#{project.web_url}-/jobs/#{pipeline_job.id}"
    assert ^temp_url = url
  end
end
