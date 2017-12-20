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
  
  @tag :wip
  test "running cloud_status" do
    monitored_job_list = ["e2e", "App-Deploy"]
    child = false 
    ccp = insert(:cross_cloud_pipeline)
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.cloud_status(monitored_job_list, child, "aws", internal_pipeline_id) == "running"
  end

  @tag :wip
  test "failed cloud_status" do
    monitored_job_list = ["e2e", "App-Deploy"]
    child = false 
    ccp = insert(:cross_cloud_pipeline, %{pipeline_jobs:
      [build(:e2e_pipeline_job, %{status: "failed"}) ,
       build(:app_deploy_pipeline_job, %{status: "success"})
      ]}) 
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.cloud_status(monitored_job_list, child, "aws", internal_pipeline_id) == "failed"
  end

  @tag :wip
  test "success parent cloud_status" do
    monitored_job_list = ["e2e", "App-Deploy"]
    child = false 
    ccp = insert(:cross_cloud_pipeline, %{pipeline_jobs:
      [build(:e2e_pipeline_job, %{status: "success"}) ,
       build(:app_deploy_pipeline_job, %{status: "success"})
      ]}) 
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.cloud_status(monitored_job_list, child, "aws", internal_pipeline_id) == "success"
  end

  @tag :wip
  test "running child cloud_status -- job status success ignored when a child" do
    # The Backend Dashboard will NOT set the badge status to success when a 
    # child -- it's ignored for a child 
    monitored_job_list = ["e2e", "App-Deploy"]
    child = true 
    ccp = insert(:cross_cloud_pipeline, %{pipeline_jobs:
      [build(:e2e_pipeline_job, %{status: "running"}) ,
       build(:app_deploy_pipeline_job, %{status: "success"})
      ]}) 
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.cloud_status(monitored_job_list, child, "aws", internal_pipeline_id) == "running"
  end

  test "monitored_job_list" do
    # The Backend Dashboard will NOT set the badge status to success when a 
    # child -- it's ignored for a child 
    ccskpm = insert(:cross_cloud_source_key_project_monitor)
    CncfDashboardApi.GitlabMonitor.migrate_source_key_monitor(ccskpm.id)
    # assert CncfDashboardApi.GitlabMonitor.monitored_job_list("cross-project") == ["e2e", "App-Deploy"] 
    assert CncfDashboardApi.GitlabMonitor.monitored_job_list("cross-project") == ["App-Deploy"] 
  end

  # test "upsert_pipeline_monitor", %{socket: socket} do 
  test "stable update: upsert_pipeline_monitor" do 
    skpm = insert(:source_key_project_monitor)
    # check insert 
    CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
    # {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project, %{ref_monitors: []})
    skpj = insert(:source_key_project, %{new_id: projects.id})
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    pipeline_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineMonitor, :count, :id)  
    # source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
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
    assert (stable_badge.status == "running" || stable_badge.status == "success")
    # assert stable_badge.status == "success"

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
    # {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project, %{ref_monitors: []})
    skpj = insert(:source_key_project, %{new_id: projects.id})
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    pipeline_monitor_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineMonitor, :count, :id)  
    # source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
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
    assert (head_badge.status == "running" || head_badge.status == "success")
    # assert head_badge.status == "success"
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
        [build(:pipeline_job, 
               %{name: "compile"}) ]})]} )
    pipeline = project.pipelines |> List.first
    pipeline_job = pipeline.pipeline_jobs |> List.first
    skpj = insert(:source_key_pipeline_job, %{new_id: pipeline_job.id})

    url = CncfDashboardApi.GitlabMonitor.compile_url(pipeline.id)
    temp_url = "#{project.web_url}/-/jobs/#{skpj.source_id}"
    assert ^temp_url = url
  end

  @tag :wip
  test "successfull deploy_url" do 
    project = insert(:project, %{pipelines: 
      [build(:pipeline, %{pipeline_jobs:
        [build(:pipeline_job, %{name: "App-Deploy", status: "success"}),
         build(:pipeline_job, %{name: "e2e", status: "success"}),
        ]
      })]} )
    child = false 
    job_names = ["App-Deploy", "e2e"]
    pipeline = project.pipelines |> List.first
    pipeline_job = pipeline.pipeline_jobs |> List.first
    skpj = insert(:source_key_pipeline_job, %{new_id: pipeline_job.id})
    pipeline_job = pipeline.pipeline_jobs |> List.last
    skpj = insert(:source_key_pipeline_job, %{source_id: "2", new_id: pipeline_job.id})

    url =  CncfDashboardApi.GitlabMonitor.deploy_url(job_names, child, pipeline.id)
    temp_url = "#{project.web_url}/-/jobs/#{skpj.source_id}"
    assert ^temp_url = url
  end

  @tag :wip
  test "failed deploy_url" do 
    project = insert(:project, %{pipelines: 
      [build(:pipeline, %{pipeline_jobs:
        [build(:pipeline_job, %{name: "App-Deploy", status: "failed"}),
         build(:pipeline_job, %{name: "e2e", status: "running"}),
        ]
      })]} )
    child = false 
    job_names = ["App-Deploy", "e2e"]
    pipeline = project.pipelines |> List.first
    pipeline_job = pipeline.pipeline_jobs |> List.first
    skpj1 = insert(:source_key_pipeline_job, %{new_id: pipeline_job.id})
    pipeline_job = pipeline.pipeline_jobs |> List.last
    skpj2 = insert(:source_key_pipeline_job, %{source_id: "2", new_id: pipeline_job.id})

    url =  CncfDashboardApi.GitlabMonitor.deploy_url(job_names, child, pipeline.id)
    #should be the first job with failed status
    temp_url = "#{project.web_url}/-/jobs/#{skpj1.source_id}"
    assert ^temp_url = url
  end

end
