defmodule CncfDashboardApi.Repo.Migrations.AddProjectIdToPipelineJobs do
  use Ecto.Migration

  def change do
    alter table(:pipeline_jobs) do
      remove :pipeline_source_id
      add :project_id, :string
      add :pipeline_id, :string
    end

  end
end
