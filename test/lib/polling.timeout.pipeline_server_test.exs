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
  
  test "let a pipeline timeout" do 
    skpm = insert(:source_key_project_monitor)
    # pm = insert(:pipeline_monitor)

    # setup the initial pipeline 
    {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
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
    Process.sleep(13000)
    # GenServer.stop(s_timeout)

    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(skpm.id) 
    #TODO check if badges set to false
    assert  false == pm_record.running 
  end

  test "set_run_to_fail" do 
    skpm = insert(:source_key_project_monitor)
    CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
    {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    projects = insert(:project)
    CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(skpm.id) 
    assert  true == pm_record.running 
    CncfDashboardApi.Polling.Timeout.PipelineServer.set_run_to_fail(skpm.id) 
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(skpm.id) 
    assert  false == pm_record.running 
  end
end
