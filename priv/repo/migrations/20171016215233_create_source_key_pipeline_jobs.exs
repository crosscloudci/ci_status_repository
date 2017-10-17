defmodule CncfDashboardApi.Repo.Migrations.CreateSourceKeyPipelineJobs do
  use Ecto.Migration

  def change do
    create table(:source_key_pipeline_jobs) do
      add :source_id, :string
      add :new_id, :integer
      add :source_name, :string

      timestamps()
    end

  end
end
