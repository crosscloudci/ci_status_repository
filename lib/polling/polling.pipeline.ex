require Logger;
defmodule CncfDashboardApi.Polling.Pipeline do
  alias CncfDashboardApi.Repo
  import Ecto.Query
  use EctoConditionals, repo: CncfDashboardApi.Repo

  def is_pipeline_complete(source_key_project_monitor_id) do
    CncfDashboardApi.GitlabMonitor.migrate_source_key_monitor(source_key_project_monitor_id)
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(source_key_project_monitor_id) 
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

  def set_run_to_fail(source_key_project_monitor_id) do
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(source_key_project_monitor_id) 

    # stop monintor from running
    pm_changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, %{running: false })
    {_, pm_record} = Repo.update(pm_changeset) 

    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: pm_record.project_id, release_type: pm_record.release_type} 
      |> find_by([:project_id, :release_type])

    {dbs_found, dbs_record} = %CncfDashboardApi.DashboardBadgeStatus{ref_monitor_id: rm_record.id, order: 1} 
                              |> find_by([:ref_monitor_id, :order])

    Repo.all(from dbs in CncfDashboardApi.DashboardBadgeStatus, where: dbs.ref_monitor_id == ^rm_record.id and dbs.status == "running") 
    |> Enum.map(fn(x) -> 
      changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(x, %{status: "failed"})

      {_, dbs_record} = Repo.update(changeset) 
      # TODO call broadcast dashboard
    end)
  end

  def monitor(source_key_project_monitor_id) do
    reciever = self()
    pid = spawn_link(fn -> 
      case CncfDashboardApi.Polling.Pipeline.poll_pipeline_until_complete(source_key_project_monitor_id) do
        {:ok, :complete} -> send reciever, { :ok, source_key_project_monitor_id } 
      end
    end)
    receive do
      { :ok, response } -> 
        Logger.info fn ->
          "Completed polling of source_key_project_monitor_id: #{response}"
        end
        response
    after 15_000 ->
      IO.puts("Timeout: setting things to fail")
        Logger.info fn ->
          "Timeout: setting badges to fail for source_key_project_monitor_id: #{source_key_project_monitor_id}"
        end
      set_run_to_fail(source_key_project_monitor_id)
      Process.exit(pid, :kill)
      # { :ok, "Job timed out" }
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
