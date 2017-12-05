defmodule CncfDashboardApi.Repo.Migrations.AddConstraintsToSourceKeyTables do
  use Ecto.Migration

  def change do
    create unique_index(:source_key_projects, [:source_id])
    create unique_index(:source_key_pipelines, [:source_id])
    create unique_index(:source_key_pipeline_jobs, [:source_id])

  end
end
