defmodule CncfDashboardApi.PipelineMonitor do
  use CncfDashboardApi.Web, :model

  schema "pipeline_monitor" do
    field :pipeline_id, :integer
    field :running, :boolean, default: false
    field :release_type, :string
    field :pipeline_type, :string
    field :project_id, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pipeline_id, :running, :release_type, :pipeline_type, :project_id])
    |> validate_required([:pipeline_id, :running, :release_type, :pipeline_type, :project_id])
  end
end
