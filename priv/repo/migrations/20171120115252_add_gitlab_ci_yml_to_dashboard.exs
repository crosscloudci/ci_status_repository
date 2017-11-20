defmodule CncfDashboardApi.Repo.Migrations.AddGitlabCiYmlToDashboard do
  use Ecto.Migration

  def change do
    alter table(:dashboard) do
      add :gitlab_ci_yml, :string
    end

  end
end
