defmodule CncfDashboardApi.Repo.Migrations.AddWebUrlToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :web_url, :string
    end

  end
end
