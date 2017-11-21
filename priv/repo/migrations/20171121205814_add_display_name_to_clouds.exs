defmodule CncfDashboardApi.Repo.Migrations.AddDisplayNameToClouds do
  use Ecto.Migration

  def change do
    alter table(:clouds) do
      add :display_name, :string
    end

  end
end
