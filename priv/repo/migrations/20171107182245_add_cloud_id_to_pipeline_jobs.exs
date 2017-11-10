defmodule CncfDashboardApi.Repo.Migrations.AddCloudIdToPipelineJobs do
  use Ecto.Migration

  def change do
    alter table(:pipeline_jobs) do
      add :cloud_id, :integer
    end

  end
end
