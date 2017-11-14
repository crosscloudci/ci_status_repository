defmodule CncfDashboardApi.Repo.Migrations.AddPipelineMonitorIdToCloudJobStatus do
  use Ecto.Migration

  def change do
    alter table(:cloud_job_status) do
      add :pipeline_monitor_id, :integer
    end

  end
end
