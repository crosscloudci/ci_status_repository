defmodule CncfDashboardApi.Pipelines do
  use CncfDashboardApi.Web, :model

  schema "pipelines" do
    field :ref, :string
    field :status, :string
    field :sha, :string
    # field :project_id, :integer
    belongs_to :project, CncfDashboardApi.Projects

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:ref, :status, :sha, :project_id])
    # |> validate_required([:ref, :status])
    |> validate_required([:ref, :status])
  end
end
