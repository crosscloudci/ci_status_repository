defmodule CncfDashboardApi.Repo.Migrations.UpdateConstraintOnRefmonitor do
  use Ecto.Migration

  def change do
    drop unique_index(:ref_monitor, [:project_id, :release_type])
    create unique_index(:ref_monitor, [:project_id, :release_type, :test_env])

  end
end
