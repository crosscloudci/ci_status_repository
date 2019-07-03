defmodule CncfDashboardApi.Repo.Migrations.AddCncfRelationToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :cncf_relation, :string
    end
  end
end
