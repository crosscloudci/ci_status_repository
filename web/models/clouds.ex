defmodule CncfDashboardApi.Clouds do
  use CncfDashboardApi.Web, :model

  schema "clouds" do
    field :cloud_name, :string
    field :active, :boolean

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:cloud_name, :active])
    |> validate_required([:cloud_name])
  end
end