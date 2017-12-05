defmodule CncfDashboardApi.Repo.Migrations.AddCloudColumnsToPipelineMonitor do
  use Ecto.Migration

  def change do
    alter table(:pipeline_monitor) do
      add :cloud, :string
      add :child_pipeline, :boolean
      add :target_project_name, :string
      add :internal_build_pipeline_id, :string

    end
  end
end
