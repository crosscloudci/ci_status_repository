defmodule CncfDashboardApi.Repo.Migrations.CreateClouds do
  use Ecto.Migration

  def change do
    create table(:clouds) do
      add :cloud_name, :string

      timestamps()
    end

  end
end
