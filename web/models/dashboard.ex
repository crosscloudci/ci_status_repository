defmodule CncfDashboardApi.Dashboard do
  use CncfDashboardApi.Web, :model

  schema "dashboard" do
    field :last_check, :utc_datetime
    field :gitlab_ci_yml, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:last_check, :gitlab_ci_yml])
    |> validate_required([:gitlab_ci_yml])
  end
end
