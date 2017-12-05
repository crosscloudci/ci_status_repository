defmodule CncfDashboardApi.Repo.Migrations.AddNewIdConstraintsToSourceKeyTables do
  use Ecto.Migration

  def change do
    create unique_index(:source_key_projects, [:new_id])
    create unique_index(:source_key_pipelines, [:new_id])
    create unique_index(:source_key_pipeline_jobs, [:new_id])

  end
end
