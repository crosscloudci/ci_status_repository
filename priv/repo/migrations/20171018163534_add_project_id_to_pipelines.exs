defmodule CncfDashboardApi.Repo.Migrations.AddProjectIdToPipelines do
  use Ecto.Migration

  def change do
    alter table(:pipelines) do
      add :project_id, :string
    end
  end
end
