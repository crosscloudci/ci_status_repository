defmodule CncfDashboardApi.Repo.Migrations.CreatePipelines do
  use Ecto.Migration

  def change do
    create table(:pipelines) do
      add :ref, :string
      add :status, :string

      timestamps()
    end

  end
end
