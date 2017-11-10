defmodule CncfDashboardApi.Repo.Migrations.AddYmlFieldsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :active, :boolean
      add :logo_url, :string
      add :display_name, :string
      add :sub_title, :string
      add :gitlab_name, :string
      add :project_url, :string
    end

  end
end
