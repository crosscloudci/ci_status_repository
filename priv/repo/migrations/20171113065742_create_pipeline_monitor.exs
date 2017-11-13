defmodule CncfDashboardApi.Repo.Migrations.CreatePipelineMonitor do
  use Ecto.Migration

  def change do
    create table(:pipeline_monitor) do
      add :pipeline_id, :integer
      add :running, :boolean, default: false, null: false
      add :release_type, :string
      add :pipeline_type, :string
      add :project_id, :integer

      timestamps()
    end

  end
end
