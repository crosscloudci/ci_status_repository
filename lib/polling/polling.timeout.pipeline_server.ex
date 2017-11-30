require Logger;
defmodule CncfDashboardApi.Polling.Timeout.PipelineServer do
  @compile if Mix.env == :test, do: :export_all

  use GenServer
  alias CncfDashboardApi.Repo
  import Ecto.Query
  use EctoConditionals, repo: CncfDashboardApi.Repo

  def start_link(name, timeout \\ 15000) do
    # Instead of passing an atom to the `name` option, we send 
    # a tuple. Here we extract this tuple to a private method
    # called `via_tuple` that can be reused for every function
    GenServer.start_link(__MODULE__, [timeout], name: via_tuple(name))
  end

  defp via_tuple(pipeline_monitor_id) do
    {:via, :gproc, {:n, :l, {:pipeline_monitor, pipeline_monitor_id}}}
  end

  def monitor_pipeline(pipeline_monitor_id, pipeline_monitor_id2, timeout \\ 15000) do
    IO.puts("monitor_pipeline: #{inspect(pipeline_monitor_id)}")
    Logger.info fn ->
      "monitor_pipeline: #{inspect(pipeline_monitor_id)}"
    end
    # And the `GenServer` callbacks will accept this tuple the same way it
    # accepts a `pid` or an atom.
    # TODO get timeout for pipeline
    GenServer.cast(via_tuple(pipeline_monitor_id), {:monitor, %{:timeout => timeout, :skpm_id => pipeline_monitor_id2}})
    # GenServer.cast(via_tuple(pipeline_monitor_id), {:monitor,  pipeline_monitor_id2})
    # GenServer.cast(via_tuple(pipeline_monitor_id), {:monitor,  pipeline_monitor_id2})
  end

  # def handle_cast({:monitor, %{:timeout => timeout, :skpm_id => skpm_id}}, state) do
  def handle_cast({:monitor, %{:timeout => timeout, :skpm_id => skpm_id}}, state) do
    # def handle_cast({:monitor, skpm_id) do

    IO.puts("handle_cast pipeline_server: #{inspect(skpm_id)}")
    Logger.info fn ->
      "handle_cast pipeline_server: #{inspect(skpm_id)}"
    end
    # monitor(skpm_id, timeout)
    ans = monitor(skpm_id, timeout)
    {:noreply, ans}
  end

  def init(timeout) do
    IO.puts("init: #{inspect(timeout)}")
    Logger.info fn ->
      "init: #{inspect(timeout)}"
    end
    {:ok, timeout}
  end

  def is_pipeline_complete(source_key_project_monitor_id) do
    IO.puts("is_pipeline_complete skpm: #{source_key_project_monitor_id}" )
    Logger.info fn ->
      "is_pipeline_complete skpm: #{source_key_project_monitor_id}"
    end
    CncfDashboardApi.GitlabMonitor.migrate_source_key_monitor(source_key_project_monitor_id)
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(source_key_project_monitor_id) 
    IO.puts("is_pipeline_complete pm_record.running: #{pm_record.running}" )
    Logger.info fn ->
      "is_pipeline_complete pm_record.running: #{pm_record.running}"
    end
    if pm_record.running do
      CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(source_key_project_monitor_id)
      ret = {:ok, :running}
    else
      ret = {:ok, :complete}
    end
    ret
  end

  defp monitor(source_key_project_monitor_id, timeout \\ 15000) do
    IO.puts("monitor skpm, timeout: #{source_key_project_monitor_id} #{timeout}" )
    Logger.info fn ->
      "monitor skpm: #{source_key_project_monitor_id} #{timeout}"
    end
    reciever = self()
    # pid = spawn_link(fn -> 
    #   case CncfDashboardApi.Polling.Pipeline.poll_pipeline_until_complete(source_key_project_monitor_id) do
    #     {:ok, :complete} -> send reciever, { :ok, source_key_project_monitor_id } 
    #   end
    # end)
    receive do
      { :ok, response } -> 
      Logger.info fn ->
        "Completed polling of source_key_project_monitor_id: #{response}"
      end
      response
      # TODO get timeout from yml
    after timeout ->
      Logger.info fn ->
        "Timeout: setting badges to fail for source_key_project_monitor_id: #{source_key_project_monitor_id}"
      end
      ret = is_pipeline_complete(source_key_project_monitor_id)
      IO.puts("is_pipeline_complete ret: #{inspect(ret)}")
      Logger.info fn ->
        "is_pipeline_complete ret: #{inspect(ret)}"
      end
      case ret do
        {:ok, :running} ->
          # only set run to fail if wh
          IO.puts("is_pipeline_complete: still running")
        # Logger.info fn ->
          #   "is_pipeline_complete: still running"
          # end
          set_run_to_fail(source_key_project_monitor_id)
        {:ok, :complete} ->
          # stop(server, reason \\ :normal, timeout \\ :infinity)
          # Process.exit(pid, :kill)
          # IO.puts("is_pipeline_complete: exiting")
        # Logger.info fn ->
          #   "is_pipeline_complete: exiting"
          # end
      end
      IO.puts("Timeout: exiting")
      Logger.info fn ->
        "Timeout: exiting"
      end
      Process.exit(self(), :kill)
      {:ok, :complete}
      { :error, "Job timed out" }
    end
  end

  defp set_run_to_fail(source_key_project_monitor_id) do
    IO.puts("set_run_to_fail")
    Logger.info fn ->
      "set_run_to_fail"
    end
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.pipeline_monitor(source_key_project_monitor_id) 

    # stop monintor from running
    pm_changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, %{running: false })
    {_, pm_record} = Repo.update(pm_changeset) 

    # only two ref monitors, head and stable
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: pm_record.project_id, release_type: pm_record.release_type} 
                            |> find_by([:project_id, :release_type])

                            # TODO, remove in favor of setting *all* badges that are still running to failed
    {dbs_found, dbs_record} = %CncfDashboardApi.DashboardBadgeStatus{ref_monitor_id: rm_record.id, order: 1} 
                              |> find_by([:ref_monitor_id, :order])

    Repo.all(from dbs in CncfDashboardApi.DashboardBadgeStatus, where: dbs.ref_monitor_id == ^rm_record.id and dbs.status == "running") 
    |> Enum.map(fn(x) -> 
      changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(x, %{status: "failed"})
      {_, dbs_record} = Repo.update(changeset) 
    end)

    # Call dashboard channel
    CncfDashboardApi.Endpoint.broadcast! "dashboard:*", "new_cross_cloud_call", %{reply: CncfDashboardApi.GitlabMonitor.dashboard_response} 

    Logger.info fn ->
      "Polling.Pipeline: Broadcasted json"
    end

  end
end
