defmodule CncfDashboardApi.Repo.Migrations.AddActiveToPipelineClouds do
  use Ecto.Migration

  def change do
    alter table(:clouds) do
      add :active, :boolean
    end

  end
end
