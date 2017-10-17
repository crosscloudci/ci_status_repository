defmodule CncfDashboardApi.PipelineJobs do
  use CncfDashboardApi.Web, :model

  schema "pipeline_jobs" do
    field :name, :string
    field :status, :string
    field :ref, :string
    field :pipeline_source_id, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :status, :ref, :pipeline_source_id])
    |> validate_required([:name, :status, :ref])
    # |> validate_required([:name, :status, :ref, :pipeline_source_id])
  end
end
