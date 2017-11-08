defmodule CncfDashboardApi.SourceKeyProjects do
  use CncfDashboardApi.Web, :model

  schema "source_key_projects" do
    field :source_id, :string
    # field :new_id, :integer
    field :source_name, :string
    belongs_to :project, CncfDashboardApi.Projects, foreign_key: :new_id
    has_many :source_key_project_monitor, CncfDashboardApi.SourceKeyProjectMonitor, foreign_key: :source_project_id, references: :source_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:source_id, :new_id, :source_name])
    # |> validate_required([:source_id, :new_id, :source_name])
    |> validate_required([:source_id])
  end
end
