defmodule CncfDashboardApi.Repo.Migrations.CreateGitLab.Projects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      add :ssh_url_to_repo, :string
      add :http_url_to_repo, :string

      timestamps()
    end

  end
end
