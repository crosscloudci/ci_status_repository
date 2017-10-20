defmodule CncfDashboardApi.Repo.Migrations.ChangeProjectIdAndPipelineIdToInteger do
  use Ecto.Migration

  def change do
    alter table(:pipeline_jobs) do
      remove :project_id
      remove :pipeline_id
      add :project_id, :integer
      add :pipeline_id, :integer
    end
    alter table(:pipelines) do
      remove :project_id
      add :project_id, :integer
    end

  end
end
