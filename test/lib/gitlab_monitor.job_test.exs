require IEx;
# require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.GitlabMonitor.Job.JobTest do
  use CncfDashboardApi.ChannelCase

  alias CncfDashboardApi.DashboardChannel

  import Ecto.Query
  import CncfDashboardApi.Factory
  use ExUnit.Case
  
  test "running build badge_status_by_pipeline_id" do
    monitored_job_list = ["container", "compile"]
    child = false 
    ccp = insert(:build_pipeline)
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(monitored_job_list, child, "", internal_pipeline_id) == "running"
  end

  test "running cross_cloud badge_status_by_pipeline_id" do
    monitored_job_list = ["e2e", "App-Deploy"]
    child = false 
    ccp = insert(:cross_cloud_pipeline)
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(monitored_job_list, child, "aws", internal_pipeline_id) == "running"
  end

  test "failed badge_status_by_pipeline_id" do
    monitored_job_list = ["e2e", "App-Deploy"]
    child = false 
    ccp = insert(:cross_cloud_pipeline, %{pipeline_jobs:
      [build(:e2e_pipeline_job, %{status: "failed"}) ,
       build(:app_deploy_pipeline_job, %{status: "success"})
      ]}) 
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(monitored_job_list, child, "aws", internal_pipeline_id) == "failed"
  end

  test "success parent badge_status_by_pipeline_id" do
    monitored_job_list = ["e2e", "App-Deploy"]
    child = false 
    ccp = insert(:cross_cloud_pipeline, %{pipeline_jobs:
      [build(:e2e_pipeline_job, %{status: "success"}) ,
       build(:app_deploy_pipeline_job, %{status: "success"})
      ]}) 
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(monitored_job_list, child, "aws", internal_pipeline_id) == "success"
  end

  test "running child badge_status_by_pipeline_id -- job status success ignored when a child" do
    # The Backend Dashboard will NOT set the badge status to success when a 
    # child -- it's ignored for a child 
    monitored_job_list = ["e2e", "App-Deploy"]
    child = true 
    ccp = insert(:cross_cloud_pipeline, %{pipeline_jobs:
      [build(:e2e_pipeline_job, %{status: "running"}) ,
       build(:app_deploy_pipeline_job, %{status: "success"})
      ]}) 
    internal_pipeline_id = ccp.id
    assert CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(monitored_job_list, child, "aws", internal_pipeline_id) == "running"
  end

  @tag timeout: 300_000 
  test "monitored_job_list" do
    # The Backend Dashboard will NOT set the badge status to success when a 
    # child -- it's ignored for a child 
    ccskpm = insert(:cross_cloud_source_key_project_monitor)
    CncfDashboardApi.GitlabMonitor.migrate_source_key_monitor(ccskpm.id)
    assert CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-project") == ["Build-Source", "App-Deploy", "e2e"] 
  end

  test "compile badge_url" do 
    project = insert(:project, %{pipelines: 
      [build(:pipeline, %{pipeline_jobs:
        [build(:pipeline_job, 
               %{name: "compile"}) ]})]} )
    pipeline = project.pipelines |> List.first
    pipeline_job = pipeline.pipeline_jobs |> List.first
    skpj = insert(:source_key_pipeline_job, %{new_id: pipeline_job.id})

    job_names = ["container", "compile"]
    url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, pipeline.id)
    temp_url = "#{project.web_url}/-/jobs/#{skpj.source_id}"
    assert ^temp_url = url
  end

  test "successful deploy badge_url" do 
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

    url =  CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, child, pipeline.id)
    temp_url = "#{project.web_url}/-/jobs/#{skpj.source_id}"
    assert ^temp_url = url
  end

  test "failed deploy badge_url" do 
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

    url =  CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, child, pipeline.id)
    #should be the first job with failed status
    temp_url = "#{project.web_url}/-/jobs/#{skpj1.source_id}"
    assert ^temp_url = url
  end

  test "failed deploy badge_url with skipped" do 
    project = insert(:project, %{pipelines: 
      [build(:pipeline, %{pipeline_jobs:
        [build(:pipeline_job, %{name: "App-Deploy", status: "running"}),
         build(:pipeline_job, %{name: "e2e", status: "skipped"}),
        ]
      })]} )
    child = false 
    job_names = ["App-Deploy", "e2e"]
    pipeline = project.pipelines |> List.first
    pipeline_job = pipeline.pipeline_jobs |> List.first
    Logger.info fn ->
      "first pipeline_job: #{inspect(pipeline_job)}"
    end
    skpj1 = insert(:source_key_pipeline_job, %{new_id: pipeline_job.id})
    pipeline_job = pipeline.pipeline_jobs |> List.last
    skpj2 = insert(:source_key_pipeline_job, %{source_id: "2", new_id: pipeline_job.id})

    url =  CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, child, pipeline.id)
    #should be the first job with failed status
    temp_url = "#{project.web_url}/-/jobs/#{skpj1.source_id}"
    Logger.info fn ->
      "monitored url: #{inspect(temp_url)}"
    end
    assert ^temp_url = url
  end
end
