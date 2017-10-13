defmodule CncfDashboardApi.Pipelines do
  use CncfDashboardApi.Web, :model

  schema "pipelines" do
    field :ref, :string
    field :status, :string
    field :sha, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:ref, :status, :sha])
    # |> validate_required([:ref, :status])
    |> validate_required([:ref, :status])
  end
end
