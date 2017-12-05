defmodule CncfDashboardApi.Repo.Migrations.AddCloudColumnsToSourceProjectMonitor do
  use Ecto.Migration

  def change do
    alter table(:source_key_project_monitor) do
      add :cloud, :string
      add :child_pipeline, :boolean
      add :target_project_name, :string
      add :project_build_pipeline_id, :string
  end

  end
end
