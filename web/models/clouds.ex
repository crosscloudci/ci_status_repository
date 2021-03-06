defmodule CncfDashboardApi.Clouds do
  use CncfDashboardApi.Web, :model

  schema "clouds" do
    field :cloud_name, :string
    field :display_name, :string
    field :active, :boolean
    field :order, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:cloud_name, :display_name, :active, :order])
    |> validate_required([:cloud_name, :order])
  end
end
