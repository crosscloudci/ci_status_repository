defmodule CncfDashboardApi.RefMonitor do
  use CncfDashboardApi.Web, :model

  schema "ref_monitor" do
    field :ref, :string
    field :status, :string
    field :sha, :string
    field :release_type, :string
    field :project_id, :integer
    field :order, :integer
    field :pipeline_id, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:ref, :status, :sha, :release_type, :project_id, :order, :pipeline_id])
    |> validate_required([:ref, :status, :sha, :release_type, :project_id, :order, :pipeline_id])
  end
end
