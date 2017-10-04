defmodule CncfDashboardApi.Projects do
  use CncfDashboardApi.Web, :model

  schema "projects" do
    field :name, :string
    field :ssh_url_to_repo, :string
    field :http_url_to_repo, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :ssh_url_to_repo, :http_url_to_repo])
    |> validate_required([:name, :ssh_url_to_repo, :http_url_to_repo])
  end
end
