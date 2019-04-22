require IEx;
# require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.Polling.PipelineTest do
  use CncfDashboardApi.ChannelCase

  alias CncfDashboardApi.DashboardChannel

  import Ecto.Query
  import CncfDashboardApi.Factory
  # use EctoConditionals, repo: CncfDashboardApi.Repo
  use ExUnit.Case
  # use CncfDashboardApi.ModelCase
  
  # @tag timeout: 320_000 
  # @tag :wip
  # test "monitor a pipeline" do 
  #   skpm = insert(:source_key_project_monitor)
  #   pm = insert(:pipeline_monitor)
  #   CncfDashboardApi.Polling.Pipeline.monitor(skpm.id) 
  #   {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(skpm.id) 
  #   assert  false == pm_record.running 
  # end

  # @tag :wip
  # test "set_run_to_fail" do 
  #   skpm = insert(:source_key_project_monitor)
  #   CncfDashboardApi.Endpoint.subscribe(self, "dashboard:*")
  #   # {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
  #   projects = insert(:project)
  #   CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm.id)
  #   {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(skpm.id) 
  #   assert  true == pm_record.running 
  #   CncfDashboardApi.Polling.Pipeline.set_run_to_fail(skpm.id) 
  #   {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(skpm.id) 
  #   assert  false == pm_record.running 
  # end
end
