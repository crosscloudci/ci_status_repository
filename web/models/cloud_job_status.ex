defmodule CncfDashboardApi.CloudJobStatus do
  use CncfDashboardApi.Web, :model

  schema "cloud_job_status" do
    field :cloud_id, :integer
    field :status, :string
    field :pipeline_id, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:cloud_id, :status, :pipeline_id])
    |> validate_required([:cloud_id, :status, :pipeline_id])
  end
end
