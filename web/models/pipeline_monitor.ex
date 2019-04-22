defmodule CncfDashboardApi.PipelineMonitor do
  use CncfDashboardApi.Web, :model

  schema "pipeline_monitor" do
    field :pipeline_id, :integer
    field :running, :boolean, default: false
    field :release_type, :string
    field :pipeline_type, :string
    field :project_id, :integer
    field :cloud, :string
    field :child_pipeline, :boolean
    field :target_project_name, :string
    field :internal_build_pipeline_id, :integer
    field :provision_pipeline_id, :integer
    field :kubernetes_release_type, :string, default: ""
    field :arch, :string, default: ""
    # belongs_to :internal_pipeline, CncfDashboardApi.Pipelines, foreign_key: :internal_build_pipeline_id, references: :id


    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pipeline_id, :running, :release_type, :pipeline_type, :project_id, :cloud,
                     :child_pipeline, :target_project_name, :internal_build_pipeline_id, :provision_pipeline_id,
    :kubernetes_release_type, :arch])
    |> validate_required([:pipeline_id, :running, :release_type, :pipeline_type, :project_id])
  end
end
