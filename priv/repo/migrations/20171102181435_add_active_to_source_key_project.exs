defmodule CncfDashboardApi.Repo.Migrations.AddActiveToSourceKeyProject do
  use Ecto.Migration

  def change do
    alter table(:source_key_projects) do
      add :active, :boolean
    end

  end
end
