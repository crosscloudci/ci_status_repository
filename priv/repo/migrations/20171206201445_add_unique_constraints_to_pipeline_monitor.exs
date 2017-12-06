defmodule CncfDashboardApi.Repo.Migrations.AddUniqueConstraintsToPipelineMonitor do
  use Ecto.Migration

  def change do
    create unique_index(:pipeline_monitor, [:project_id, :pipeline_id, :pipeline_type, :release_type])

  end
end
