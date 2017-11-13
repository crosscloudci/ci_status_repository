defmodule CncfDashboardApi.Repo.Migrations.CreateBuildJobStatus do
  use Ecto.Migration

  def change do
    create table(:build_job_status) do
      add :status, :string
      add :pipeline_id, :integer
      add :pipeline_monitor_id, :integer

      timestamps()
    end

  end
end
