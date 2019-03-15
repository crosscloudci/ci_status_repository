defmodule CncfDashboardApi.Repo.Migrations.AddTestEnvToRefmonitor do
  use Ecto.Migration

  def change do
    alter table(:ref_monitor) do
      add :test_env, :string
    end

  end
end
