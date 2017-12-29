defmodule CncfDashboardApi.Polling.Supervisor.Pipeline do
  use Supervisor

  def start_link do
		Supervisor.start_link(__MODULE__, [], name: :pipeline_supervisor)
  end


 @doc """
  starts a pipeline 'last check' based on `name`, `skpm_id`, and `timeout`.

  name is a unique identifier across the cluster, given gproc is set up

  skpm_id is the source key pipeline monitor id

  timeout is based on milliseconds

  Returns `:ok`
  """
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

