defmodule CncfDashboardApi.Repo.Migrations.AddShaToPipelines do
  use Ecto.Migration

  def change do
    alter table(:pipelines) do
      add :sha, :string
    end
  end
end
