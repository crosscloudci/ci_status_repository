defmodule CncfDashboardApi.Repo.Migrations.AddRepositoryUrlAndTimeoutToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :repository_url, :string
      add :timeout, :integer
    end

  end
end
