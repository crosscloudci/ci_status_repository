require Logger;
defmodule CncfDashboardApi.Polling.Pipeline do
  use EctoConditionals, repo: CncfDashboardApi.Repo

  # TODO Watcher: run for 2 hours for a source_key_project_monitor
  # TODO Watcher: Get the pipeline_monitor (project_id, pipeline_id, release_type) for the source_key_project_monitor 
  # TODO Watcher: if time expires, get ref_monitor for project_id, pipeline_id
  # TODO Watcher: if time expires, get all dashboard_badge_statuses for ref_monitor with status of running,
  #               set to failed
  #
  # TODO Watcher: if time expires, set pipeline_monitor running to false  
  #
  # TODO in gitlab monitor, if all badge_status = success or failed, pipeline_monitor.running = false
  # TODO in gitlab monitor, return pipeline_monitor.running
  #
  # TODO Get the passed source_key_project_monitor  
  #
  # TODO poll_loop 
  # TODO Get the pipeline_monitor (project_id, pipeline_id, release_type) for the source_key_project_monitor 
  # TODO check if pipeline_monitor is running, 
  #       if running,
  #          call upsert_pipeline_monitor with source_key_project_monitor
  #            if running sleep for 2 minutes
  #               call poll_loop
  #       if not running, return success (kill watcher) for source_key_project_monitor 
  #
  #

  def is_pipeline_complete(source_key_project_monitor_id) do

    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(source_key_project_monitor_id) 
      # check if pipeline_monitor is running, 
      #       if running, 
      #          call upsert_pipeline_monitor with source_key_project_monitor
    if pm_record.running do
      CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(source_key_project_monitor_id)
      {:ok, :running}
    else
      {:ok, :complete}
    end
  end

  def poll_pipeline_until_complete(source_key_project_monitor_id) do
    case CncfDashboardApi.Polling.Pipeline.is_pipeline_complete(source_key_project_monitor_id) do
      # if running sleep for 2 minutes
      {:ok, :running} ->
        IO.puts("poll_pipeline_until_complete")
        Logger.info fn ->
          "poll_pipeline_until_complete "
        end
        :timer.sleep(:timer.seconds(5))
        inifinite_poll_loop()
      {:ok, :complete} ->
        {:ok, :complete}
    end
  end

  # def set_run_to_fail do
  #   {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(source_key_project_monitor_id) 
  #   {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id,
  #     release_type: pipeline_monitor.release_type} 
  #     |> find_by([:project_id, :release_type])
  # end

  def monitor(source_key_project_monitor_id) do
    reciever = self()
    pid = spawn_link(fn -> 
      CncfDashboardApi.Polling.Pipeline.poll_pipeline_until_complete(source_key_project_monitor_id)
      send reciever, { :ok, source_key_project_monitor_id } 
    end)
    receive do
      { :ok, response } -> 
        IO.puts("Got a response!")
        response
    after 15_000 ->
      IO.puts("Killing due to timeout.. sigh")
      Process.exit(pid, :kill)
      { :error, "Job timed out" }
    end
  end

  def inifinite_poll_loop() do
    case :error do
      :ok -> :ok
      :error ->
        IO.puts("Polling")
        :timer.sleep(:timer.seconds(1))
        inifinite_poll_loop()
    end
  end

  def timed_job_interval(job_data) do
    reciever = self()
    pid = spawn_link(fn -> 
      CncfDashboardApi.Polling.Pipeline.inifinite_poll_loop
      send reciever, { :ok, job_data } 
    end)
    receive do
      { :ok, response } -> 
        IO.puts("Got a response!")
        response
    after 4_000 ->
      IO.puts("Killing due to timeout.. sigh")
      Process.exit(pid, :kill)
      { :error, "Job timed out" }
    end
  end
end
