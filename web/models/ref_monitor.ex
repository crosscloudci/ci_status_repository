defmodule CncfDashboardApi.RefMonitor do
  use CncfDashboardApi.Web, :model

  schema "ref_monitor" do
    field :ref, :string
    field :status, :string
    field :sha, :string
    field :release_type, :string
    field :test_env, :string
    # field :project_id, :integer
    belongs_to :project, CncfDashboardApi.Projects
    field :order, :integer
    field :pipeline_id, :integer
    has_many :dashboard_badge_statuses, CncfDashboardApi.DashboardBadgeStatus, foreign_key: :ref_monitor_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:ref, :status, :sha, :release_type, :project_id, :order, :pipeline_id, :test_env])
    # |> validate_required([:ref, :status, :sha, :release_type, :project_id, :order, :pipeline_id])
    # initialized ref_monitors will have no pipeline (they exist before a build)
    |> validate_required([:ref, :status, :sha, :release_type, :project_id, :order, :test_env])
    
    |> unique_constraint(:project_id_release_type_test_env, message: "Project Id, Release Type, and Test Env must be unique for a Ref Monitor")
  end
end
