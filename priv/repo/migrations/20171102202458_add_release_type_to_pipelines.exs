defmodule CncfDashboardApi.Repo.Migrations.AddReleaseTypeToPipelines do
  use Ecto.Migration

  def change do
    alter table(:pipelines) do
      add :release_type, :string
    end

  end
end
