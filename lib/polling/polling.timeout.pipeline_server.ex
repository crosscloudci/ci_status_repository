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
    skpm_monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                       where: skpm.id == ^source_key_project_monitor_id) |> List.first
    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(source_key_project_monitor_id) 
    Logger.info fn ->
      "is_pipeline_complete pm_record.running: #{pm_record.running}"
    end
    if pm_record.running do
        case pm_record.pipeline_type  do
          # "build" ->
          n when n in ["deploy"] ->
            #if deploy pipeline, check build pipeline as well
            #need skpm_id for the project id (retrieve by source_pipeline_id as well)
            skpm_build_monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
              where: skpm.source_pipeline_id == ^skpm_monitor.project_build_pipeline_id) |> List.first
            CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(skpm_build_monitor.id)
            CncfDashboardApi.GitlabMonitor.PMToDashboard.pm_stage_to_project_rows({pm_record.pipeline_type, pm_record})
            |> CncfDashboardApi.GitlabMonitor.PMToDashboard.project_rows_to_columns()
          _ ->
            :ok
        end
         CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(source_key_project_monitor_id)
      {:ok, :running}
    else
      {:ok, :complete}
    end
  end

  defp set_badge_to_failed(pm_record) do
    Logger.info fn ->
      "set_build_badge_to_failed"
    end

    # https://github.com/vulk/cncf_ci/issues/29
    # two ref monitors needs to be updated for each build pm_record: test_env: head and stable 
    # TODO separate out the update into separate call
        CncfDashboardApi.GitlabMonitor.PMToDashboard.pm_stage_to_project_rows({pm_record.pipeline_type, pm_record})
        |> CncfDashboardApi.GitlabMonitor.PMToDashboard.project_rows_to_columns()
        |> CncfDashboardApi.GitlabMonitor.PMToDashboard.columns_to_timedout_columns
  end

  defp set_run_to_fail(source_key_project_monitor_id) do
    Logger.info fn ->
      "upserting and checking one last time: set_run_to_fail"
    end

    {pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(source_key_project_monitor_id) 

    # stop monitor from running
    pm_changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, %{running: false })
    {_, pm_record} = Repo.update(pm_changeset) 

    Logger.info fn ->
      "set_run_to_fail pm_record: #{inspect(pm_record)}"
    end

    set_badge_to_failed(pm_record) 

    # Call dashboard channel
    CncfDashboardApi.GitlabMonitor.Dashboard.broadcast()

    Logger.info fn ->
      "Polling.Pipeline: Broadcasted json"
    end

  end
end
