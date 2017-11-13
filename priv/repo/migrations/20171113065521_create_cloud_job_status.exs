defmodule CncfDashboardApi.Repo.Migrations.CreateCloudJobStatus do
  use Ecto.Migration

  def change do
    create table(:cloud_job_status) do
      add :cloud_id, :integer
      add :status, :string
      add :pipeline_id, :integer

      timestamps()
    end

  end
end
