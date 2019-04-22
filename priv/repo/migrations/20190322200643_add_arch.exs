defmodule CncfDashboardApi.Repo.Migrations.AddArch do
  use Ecto.Migration

  def change do
    alter table(:source_key_project_monitor) do
      add :arch, :string
    end
    alter table(:pipeline_monitor) do
      add :arch, :string
    end

  end
end
