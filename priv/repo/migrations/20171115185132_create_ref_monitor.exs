defmodule CncfDashboardApi.Repo.Migrations.CreateRefMonitor do
  use Ecto.Migration

  def change do
    create table(:ref_monitor) do
      add :ref, :string
      add :status, :string
      add :sha, :string
      add :release_type, :string
      add :project_id, :integer
      add :order, :integer
      add :pipeline_id, :integer

      timestamps()
    end

  end
end
