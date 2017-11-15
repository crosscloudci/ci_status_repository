defmodule CncfDashboardApi.DashboardBadgeStatus do
  use CncfDashboardApi.Web, :model

  schema "dashboard_badge_status" do
    field :status, :string
    field :cloud_id, :integer
    field :ref_monitor_id, :integer
    field :order, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:status, :cloud_id, :ref_monitor_id, :order])
    |> validate_required([:status, :cloud_id, :ref_monitor_id, :order])
  end
end
