defmodule CncfDashboardApi.BuildJobStatus do
  use CncfDashboardApi.Web, :model

  schema "build_job_status" do
    field :status, :string
    field :pipeline_id, :integer
    field :pipeline_monitor_id, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:status, :pipeline_id, :pipeline_monitor_id])
    |> validate_required([:status, :pipeline_id, :pipeline_monitor_id])
  end
end
