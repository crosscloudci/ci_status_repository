defmodule CncfDashboardApi.Polling.Supervisor.Pipeline do
  use Supervisor

  def start_link do
		Supervisor.start_link(__MODULE__, [], name: :pipeline_supervisor)
  end

  def start_pipeline(name) do
    Supervisor.start_child(:pipeline_supervisor, [name])
  end

  def init(_) do
    children = [
      worker(CncfDashboardApi.Polling.Timeout.PipelineServer, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end

