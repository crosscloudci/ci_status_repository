defmodule CncfDashboardApi.Repo.Migrations.AddK8sArchConstraintToRefmonitor do
  use Ecto.Migration

  def change do
    drop unique_index(:ref_monitor, [:project_id, :release_type, :test_env])
    create unique_index(:ref_monitor, [:project_id, :release_type, :kubernetes_release_type, :test_env, :arch])
  end
end
