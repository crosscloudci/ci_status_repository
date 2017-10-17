defmodule Mix.Tasks.GitlabData.LoadProjects do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Upsert all projects"
  def run(_) do
    ensure_started(CncfDashboardApi.Repo, [])
    upsert_count = CncfDashboardApi.GitlabMigrations.upsert_projects()
    Mix.shell.info(inspect(upsert_count) <> " records upserted")
  end
end
