defmodule CncfDashboardApi.Repo.Migrations.AddMoreYmlFieldsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      remove :gitlab_name
    end
    alter table(:projects) do
      add :yml_gitlab_name, :string
      add :yml_name, :string
    end

  end
end
