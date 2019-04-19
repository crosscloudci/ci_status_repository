defmodule CncfDashboardApi.Repo.Migrations.AddArchToRefmonitor do
  use Ecto.Migration

  def change do
    alter table(:ref_monitor) do
      add :arch, :string
      add :kubernetes_release_type, :string
    end
  end
end
