require IEx;
# require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.Polling.Timeout.PipelineServerTest do
  use CncfDashboardApi.ChannelCase

  alias CncfDashboardApi.DashboardChannel

  import Ecto.Query
  import CncfDashboardApi.Factory
  # use EctoConditionals, repo: CncfDashboardApi.Repo
  use ExUnit.Case
  # use CncfDashboardApi.ModelCase
  
  test "run a kubernetes test" do
    # scenario 1
    # call kubernetes script
    # System.cmd("whoami", [])
    # set a premature timeout
    # how do we set a premature timeout on the real db?
    #   mock the timeout?
    #
    # scenario 2
    # mock *all* of the build/compile data
    # do a timeout 
  end

  @tag timeout: 470_000 
  @tag :wip
  test "let a build pipeline timeout" do 
    skpm = insert(:source_key_project_monitor)
    # pm = insert(:pipeline_monitor)

    # setup the initial pipeline 
    # {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project, %{ref_monitors: []})
    skpj = insert(:source_key_project, %{new_id: projects.id})
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)

    # test the genserver
    # now in supervisor
    # {:ok, s_timeout} = CncfDashboardApi.Polling.Supervisor.Pipeline.start_link 
    # key create a new process that is unique for skpm.id and timesout in 1 second
    CncfDashboardApi.Polling.Supervisor.Pipeline.start_pipeline(skpm.id, skpm.id, 1000) 
    # GenServer.stop(s_timeout)
    # Wait for the timeout to complete
    Process.sleep(37000)
    # GenServer.stop(s_timeout)

    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(skpm.id) 
    assert  false == pm_record.running 
  end

  @tag timeout: 370_000 
  @tag :wip
  test "let a deploy pipeline timeout" do 
    # pull over cross cloud and cross project projects manually in test mode 
    cc_project = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == "cross-cloud" end)
    cp_project = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == "cross-project" end)
    CncfDashboardApi.GitlabMigrations.upsert_project(cc_project["id"] |> Integer.to_string) 
    CncfDashboardApi.GitlabMigrations.upsert_project(cp_project["id"] |> Integer.to_string) 

    bskpm = insert(:build_source_key_project_monitor)
    CncfDashboardApi.GitlabMonitor.migrate_source_key_monitor(bskpm.id)
    |> CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor_info
    |> CncfDashboardApi.GitlabMonitor.upsert_gitlab_to_ref_monitor

    ccskpm = insert(:cross_project_source_key_project_monitor)
    CncfDashboardApi.GitlabMonitor.migrate_source_key_monitor(ccskpm.id)
    |> CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor_info
    |> CncfDashboardApi.GitlabMonitor.upsert_gitlab_to_ref_monitor

    # setup the initial pipeline 

    # test the genserver
    # now in supervisor
    # {:ok, s_timeout} = CncfDashboardApi.Polling.Supervisor.Pipeline.start_link 
    # key create a new process that is unique for skpm.id and timesout in 1 second
    CncfDashboardApi.Polling.Supervisor.Pipeline.start_pipeline(ccskpm.id, ccskpm.id, 1000) 
    # GenServer.stop(s_timeout)
    # Wait for the timeout to complete
    Process.sleep(37000)
    # GenServer.stop(s_timeout)

    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(ccskpm.id) 
    assert  false == pm_record.running 
  end

  @tag :wip
  @tag timeout: 370_000 
  test "set_run_to_fail" do 
    skpm = insert(:source_key_project_monitor)
    CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
    # {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project)
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(skpm.id) 
    assert  true == pm_record.running 
    CncfDashboardApi.Polling.Timeout.PipelineServer.set_run_to_fail(skpm.id) 
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(skpm.id) 
    assert  false == pm_record.running 
  end
end
