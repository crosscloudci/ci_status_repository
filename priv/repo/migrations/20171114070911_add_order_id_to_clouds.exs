defmodule CncfDashboardApi.Repo.Migrations.AddOrderIdToClouds do
  use Ecto.Migration

  def change do
    alter table(:clouds) do
      add :order, :integer
    end

  end
end
