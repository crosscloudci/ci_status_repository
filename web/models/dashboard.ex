defmodule CncfDashboardApi.Dashboard do
  use CncfDashboardApi.Web, :model

  schema "dashboard" do
    field :last_check, Timex.Ecto.Date

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:last_check])
    |> validate_required([:last_check])
  end
end
