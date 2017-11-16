defmodule CncfDashboardApi.DashboardBadgeStatus do
  use CncfDashboardApi.Web, :model

  schema "dashboard_badge_status" do
    field :status, :string
    # field :cloud_id, :integer
    belongs_to :cloud, CncfDashboardApi.Clouds
    # field :ref_monitor_id, :integer
    belongs_to :ref_monitor, CncfDashboardApi.RefMonitor
    field :order, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:status, :cloud_id, :ref_monitor_id, :order])
    # |> validate_required([:status, :cloud_id, :ref_monitor_id, :order])
    # build badges dont have a cloud_id
    |> validate_required([:status, :ref_monitor_id, :order])
  end
end
