defmodule CncfDashboardApi.Repo.Migrations.AddOrderIdToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :order, :integer
    end

  end
end
