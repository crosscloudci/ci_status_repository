defmodule CncfDashboardApi.Pipelines do
  use CncfDashboardApi.Web, :model

  schema "pipelines" do
    field :ref, :string
    field :status, :string
    field :sha, :string
    field :release_type, :string
    # field :project_id, :integer
    belongs_to :project, CncfDashboardApi.Projects
    has_many :pipeline_jobs, CncfDashboardApi.PipelineJobs, foreign_key: :pipeline_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:ref, :status, :sha, :release_type, :project_id])
    # |> validate_required([:ref, :status])
    |> validate_required([:ref, :status])
  end
end
