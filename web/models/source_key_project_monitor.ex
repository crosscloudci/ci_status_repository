defmodule CncfDashboardApi.SourceKeyProjectMonitor do
  use CncfDashboardApi.Web, :model

  schema "source_key_project_monitor" do
    field :source_project_id, :string
    field :source_pipeline_id, :string
    field :source_pipeline_job_id, :string
    field :pipeline_release_type, :string
    field :active, :boolean, default: true
    field :cloud, :string
    field :child_pipeline, :boolean
    field :target_project_name, :string
    field :project_build_pipeline_id, :string
    # causes errors
    # belongs_to :source_key_project, CncfDashboardApi.SourceKeyProjects, foreign_key: :source_project_id, references: :source_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:source_project_id, :source_pipeline_id, :source_pipeline_job_id, :pipeline_release_type, 
                     :active, :cloud, :child_pipeline, :target_project_name, :project_build_pipeline_id])
    |> validate_required([:source_project_id, :source_pipeline_id, :pipeline_release_type])
  end
end
