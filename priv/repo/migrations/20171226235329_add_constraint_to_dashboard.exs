defmodule CncfDashboardApi.Repo.Migrations.AddConstraintToDashboard do
  use Ecto.Migration

  def change do
    create unique_index(:dashboard, [:gitlab_ci_yml])

  end
end
