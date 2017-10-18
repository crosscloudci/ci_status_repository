defmodule Mix.Tasks.GitlabData.LoadPipelines do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Upsert all pipelines"
  def run(_) do
    ensure_started(CncfDashboardApi.Repo, [])
    Mix.Task.run "gitlab_data.load_projects"
    upsert_count = CncfDashboardApi.GitlabMigrations.upsert_all_pipelines
    Mix.shell.info(inspect(upsert_count) <> " records upserted")
  end
end
