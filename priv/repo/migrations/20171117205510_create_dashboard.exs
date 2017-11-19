defmodule CncfDashboardApi.Repo.Migrations.CreateDashboard do
  use Ecto.Migration

  def change do
    create table(:dashboard) do
      add :last_check, :date

      timestamps()
    end

  end
end
