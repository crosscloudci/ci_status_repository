defmodule CncfDashboardApi.Repo.Migrations.AddSourcePipelineJobIdToSourceKeyProjectMonitor do
  use Ecto.Migration

  def change do
    alter table(:source_key_project_monitor) do
      add :source_pipeline_job_id, :string
    end

  end
end
