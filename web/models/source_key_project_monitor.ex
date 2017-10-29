defmodule CncfDashboardApi.SourceKeyProjectMonitor do
  use CncfDashboardApi.Web, :model

  schema "source_key_project_monitor" do
    field :source_project_id, :string
    field :source_pipeline_id, :string
    field :stable_ref, :string
    field :active, :boolean, default: true
    # causes errors
    # belongs_to :source_key_project, CncfDashboardApi.SourceKeyProjects, foreign_key: :source_project_id, references: :source_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:source_project_id, :source_pipeline_id, :stable_ref, :active])
    |> validate_required([:source_project_id, :stable_ref])
  end
end
