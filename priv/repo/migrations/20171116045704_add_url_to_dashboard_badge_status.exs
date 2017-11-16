defmodule CncfDashboardApi.Repo.Migrations.AddUrlToDashboardBadgeStatus do
  use Ecto.Migration

  def change do
    alter table(:dashboard_badge_status) do
      add :url, :string
    end

  end
end
