defmodule CncfDashboardApi.Repo.Migrations.ChangeInternalBuildPipelineIdToInteger do
  use Ecto.Migration

  def change do
    alter table(:pipeline_monitor) do
      remove :internal_build_pipeline_id
    end
    alter table(:pipeline_monitor) do
      add :internal_build_pipeline_id, :integer
    end

  end
end
