defmodule Mix.Tasks.GitlabData.LoadPipelineJobs do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Upsert all pipelines jobs"
  def run(_) do
    ensure_started(CncfDashboardApi.Repo, [])
    Mix.Task.run "gitlab_data.load_pipelines"
    upsert_count = CncfDashboardApi.GitlabMigrations.upsert_all_pipeline_jobs
    Mix.shell.info(inspect(upsert_count) <> " records upserted")
  end
end
