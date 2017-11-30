defmodule CncfDashboardApi.Polling.Supervisor.Pipeline do
  use Supervisor

  def start_link do
		Supervisor.start_link(__MODULE__, [], name: :pipeline_supervisor)
  end

  def start_pipeline(name, skpm_id, timeout \\ 1000) do
    Supervisor.start_child(:pipeline_supervisor, [name, skpm_id, timeout])
  end

  def init(_) do
    children = [
      worker(CncfDashboardApi.Polling.Timeout.PipelineServer, [], restart: :transient )
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end

