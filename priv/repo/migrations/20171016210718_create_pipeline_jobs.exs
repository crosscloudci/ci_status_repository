defmodule CncfDashboardApi.Repo.Migrations.CreatePipelineJobs do
  use Ecto.Migration

  def change do
    create table(:pipeline_jobs) do
      add :name, :string
      add :status, :string
      add :ref, :string
      add :pipeline_source_id, :string

      timestamps()
    end

  end
end
