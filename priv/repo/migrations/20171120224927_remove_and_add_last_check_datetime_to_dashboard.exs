defmodule CncfDashboardApi.Repo.Migrations.RemoveAndAddLastCheckDatetimeToDashboard do
  use Ecto.Migration

  def change do
    alter table(:dashboard) do
      remove :last_check
    end
    alter table(:dashboard) do
      add :last_check, :utc_datetime
    end

  end
end
