defmodule CncfDashboardApi.Repo.Migrations.CreateSourceKeyProjectMonitor do
  use Ecto.Migration

  def change do
    create table(:source_key_project_monitor) do
      add :source_project_id, :string
      add :source_pipeline_id, :string
      add :stable_ref, :string

      timestamps()
    end

  end
end
