defmodule CncfDashboardApi.Repo.Migrations.AddContraintsToRefMonitor do
  use Ecto.Migration

  def change do
    create unique_index(:ref_monitor, [:project_id, :release_type])
  end
end
