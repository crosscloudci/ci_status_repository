defmodule CncfDashboardApi.PipelineJobs do
  use CncfDashboardApi.Web, :model

  schema "pipeline_jobs" do
    field :name, :string
    field :status, :string
    field :ref, :string
    # field :pipeline_id, :integer
    # field :project_id, :integer
    belongs_to :project, CncfDashboardApi.Projects
    belongs_to :pipeline, CncfDashboardApi.Pipelines

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :status, :ref, :project_id, :pipeline_id])
    |> validate_required([:name, :status, :ref])
    # |> validate_required([:name, :status, :ref, :pipeline_source_id])
  end
end
