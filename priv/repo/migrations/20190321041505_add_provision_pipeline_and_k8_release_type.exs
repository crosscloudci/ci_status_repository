defmodule CncfDashboardApi.Repo.Migrations.AddProvisionPipelineAndK8ReleaseType do
  use Ecto.Migration

  def change do
    alter table(:source_key_project_monitor) do
      add :test_env, :string
      add :provision_pipeline_id, :string
      add :kubernetes_release_type, :string
    end
    alter table(:pipeline_monitor) do
      add :test_env, :string
      add :provision_pipeline_id, :integer
      add :kubernetes_release_type, :string
    end

  end
end
