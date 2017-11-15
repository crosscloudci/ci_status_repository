defmodule CncfDashboardApi.Repo.Migrations.CreateDashboardBadgeStatus do
  use Ecto.Migration

  def change do
    create table(:dashboard_badge_status) do
      add :status, :string
      add :cloud_id, :integer
      add :ref_monitor_id, :integer
      add :order, :integer

      timestamps()
    end

  end
end
