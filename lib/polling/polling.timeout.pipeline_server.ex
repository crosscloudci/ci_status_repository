require Logger;
defmodule CncfDashboardApi.Polling.Timeout.PipelineServer do
  @compile if Mix.env == :test, do: :export_all

  use GenServer
  alias CncfDashboardApi.Repo
  import Ecto.Query
  use EctoConditionals, repo: CncfDashboardApi.Repo

  def start_link(name, skpm_id, timeout) do
    Logger.info fn ->
      "pipeline timeout start_link name, skpm_id, timeout: #{inspect(name)} #{inspect(skpm_id)} #{inspect(timeout)}"
    end
    # Instead of passing an atom to the `name` option, we send 
    # a tuple. Here we extract this tuple to a private method
    # called `via_tuple` that can be reused for every function
    GenServer.start_link(__MODULE__, [%{:skpm_id => skpm_id, :timeout => timeout}], name: via_tuple(name))
  end

  defp via_tuple(pipeline_monitor_id) do
    {:via, :gproc, {:n, :l, {:pipeline_monitor, pipeline_monitor_id}}}
  end

  def init([%{:skpm_id => skpm_id, :timeout => timeout}]) do
    Logger.info fn ->
      "pipeline timeout init skpm_id, timeout: #{inspect(skpm_id)} #{inspect(timeout)}"
    end
    :timer.send_after(timeout, :job_timeout)
    {:ok, %{:skpm_id => skpm_id, :timeout => timeout}}
  end

  def handle_info(:job_timeout, state = %{:skpm_id => source_key_project_monitor_id, :timeout => timeout}) do
    Logger.info fn ->
      "pipeline timeout job_timeout: #{inspect(state)}"
    end
    case is_pipeline_complete(source_key_project_monitor_id) do
      {:ok, :running} ->
        # only set run to fail if wh
      Logger.info fn ->
        "is_pipeline_complete: still running"
      end
      set_run_to_fail(source_key_project_monitor_id)
      {:ok, :complete} -> :ok 
    end
    {:stop, :normal, state}
  end

  def is_pipeline_complete(source_key_project_monitor_id) do
    Logger.info fn ->
      "is_pipeline_complete skpm: #{source_key_project_monitor_id}"
    end
    CncfDashboardApi.GitlabMonitor.migrate_source_key_monitor(source_key_project_monitor_id)
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(source_key_project_monitor_id) 
    Logger.info fn ->
      "is_pipeline_complete pm_record.running: #{pm_record.running}"
    end
    if pm_record.running do
      CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(source_key_project_monitor_id)
      {:ok, :running}
    else
      {:ok, :complete}
    end
  end

  defp set_badge_to_failed(pm_record, order) do
    Logger.info fn ->
      "set_build_badge_to_failed"
    end

    # only two ref monitors, head and stable
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: pm_record.project_id, 
      release_type: pm_record.release_type} 
      |> find_by([:project_id, :release_type])

      # TODO, remove in favor of setting *all* badges that are still running to failed
    {dbs_found, dbs_record} = %CncfDashboardApi.DashboardBadgeStatus{ref_monitor_id: rm_record.id, order: order} 
                              |> find_by([:ref_monitor_id, :order])

    Repo.all(from dbs in CncfDashboardApi.DashboardBadgeStatus, where: dbs.ref_monitor_id == ^rm_record.id and dbs.status == "running") 
    |> Enum.map(fn(x) -> 
      Logger.error fn ->
        "Polling.Timeout.Pipeline setting badge to failed: #{inspect(x)}"
      end
      changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(x, %{status: "failed"})
      {_, dbs_record} = Repo.update(changeset) 
    end)
  end

  defp set_run_to_fail(source_key_project_monitor_id) do
    Logger.info fn ->
      "set_run_to_fail"
    end

    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(source_key_project_monitor_id) 

    # stop monitor from running
    pm_changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, %{running: false })
    {_, pm_record} = Repo.update(pm_changeset) 

    Logger.info fn ->
      "set_run_to_fail pm_record: #{inspect(pm_record)}"
    end

    case CncfDashboardApi.GitlabMonitor.Pipeline.is_deploy_pipeline_type(pm_record.project_id) do
      true -> true
        badge_order = CncfDashboardApi.GitlabMonitor.cloud_order_by_name(pm_record.cloud)
        build_pm_record = CncfDashboardApi.GitlabMonitor.PipelineMonitor.build_pipeline_monitor_by_deploy_pipeline_monitor(pm_record)
        Logger.info fn ->
          "set_run_to_fail badge_order, build_pm_record: #{inspect(badge_order)}, #{inspect(build_pm_record)}"
        end
        set_badge_to_failed(build_pm_record, badge_order) 
      _ -> "build"
        build_badge_order = 1 
        set_badge_to_failed(pm_record, build_badge_order) 
    end

    # Call dashboard channel
    CncfDashboardApi.GitlabMonitor.Dashboard.broadcast()

    Logger.info fn ->
      "Polling.Pipeline: Broadcasted json"
    end

  end
end
