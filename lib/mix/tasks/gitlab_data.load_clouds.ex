defmodule Mix.Tasks.GitlabData.LoadClouds do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Upsert all clouds"
  def run(_) do
    ensure_started(CncfDashboardApi.Repo, [])
		Application.ensure_all_started :yaml_elixir
    upsert_count = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    Mix.shell.info(inspect(upsert_count) <> " records upserted")
  end
end
