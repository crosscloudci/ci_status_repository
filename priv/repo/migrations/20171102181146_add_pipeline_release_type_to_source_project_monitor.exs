defmodule CncfDashboardApi.Repo.Migrations.AddPipelineReleaseTypeToSourceProjectMonitor do
  use Ecto.Migration

  def change do
    alter table(:source_key_project_monitor) do
      remove :stable_ref
      add :pipeline_release_type, :string
    end

  end
end
