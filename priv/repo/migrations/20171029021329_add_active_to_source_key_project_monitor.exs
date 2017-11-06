defmodule CncfDashboardApi.Repo.Migrations.AddActiveToSourceKeyProjectMonitor do
  use Ecto.Migration

  def change do
    alter table(:source_key_project_monitor) do
      add :active, :boolean, default: true
  end

  end
end
