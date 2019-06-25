defmodule CncfDashboardApi.Projects do
  use CncfDashboardApi.Web, :model

  schema "projects" do
    field :name, :string
    field :ssh_url_to_repo, :string
    field :http_url_to_repo, :string
    field :web_url, :string
    field :active, :boolean
    field :logo_url, :string
    field :display_name, :string
    field :sub_title, :string
    field :yml_name, :string
    field :yml_gitlab_name, :string
    field :project_url, :string
    field :repository_url, :string
    field :timeout, :integer
    field :order, :integer
    field :cncf_relation, :string
    has_many :pipelines, CncfDashboardApi.Pipelines, foreign_key: :project_id
    has_many :ref_monitors, CncfDashboardApi.RefMonitor, foreign_key: :project_id
    has_many :pipeline_jobs, CncfDashboardApi.PipelineJobs, foreign_key: :project_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :ssh_url_to_repo, :http_url_to_repo, :web_url, :active, :logo_url, :display_name, :sub_title, :yml_name, :yml_gitlab_name, :project_url, :repository_url, :timeout, :cncf_relation, :order])
    # |> validate_required([:name, :ssh_url_to_repo, :http_url_to_repo])
    |> validate_required([:name])
  end
end
