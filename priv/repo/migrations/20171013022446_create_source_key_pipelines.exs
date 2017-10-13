defmodule CncfDashboardApi.Repo.Migrations.CreateSourceKeyPipelines do
  use Ecto.Migration

  def change do
    create table(:source_key_pipelines) do
      add :source_id, :string
      add :new_id, :integer
      add :source_name, :string

      timestamps()
    end

  end
end
