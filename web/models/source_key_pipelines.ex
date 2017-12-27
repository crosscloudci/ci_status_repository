defmodule CncfDashboardApi.SourceKeyPipelines do
  use CncfDashboardApi.Web, :model

  schema "source_key_pipelines" do
    field :source_id, :string
    field :new_id, :integer
    field :source_name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:source_id, :new_id, :source_name])
    |> validate_required([:source_id, :new_id])
  end
end
