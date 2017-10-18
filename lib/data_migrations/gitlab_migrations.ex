require Logger;
require IEx;
require CncfDashboardApi.DataMigrations;
defmodule CncfDashboardApi.GitlabMigrations do
  import Ecto.Query
  use EctoConditionals, repo: CncfDashboardApi.Repo

	def save_project_names do
		projects = GitLabProxy.get_gitlab_project_names
		Enum.map(projects, fn(source_project) -> 

			prec = %CncfDashboardApi.Projects{name: source_project} 
			CncfDashboardApi.Repo.insert(prec) 
		end) 
  end

	def upsert_projects do
    project_map = GitLabProxy.get_gitlab_projects()
    CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      project_map,
      CncfDashboardApi.SourceKeyProjects,
      CncfDashboardApi.Projects,
      %{name: :name}
    )
  end

  def upsert_pipelines(projects) do
    Enum.map(projects, fn (%{"id" => project_id}) ->
      Logger.info fn ->
        "project_id is: " <> inspect(project_id)
      end
      #
      pipeline_map = GitLabProxy.get_gitlab_pipelines(project_id)
      pipeline_map_with_projects = Enum.reduce(pipeline_map, [], fn (x,acc) -> [Enum.into(x, %{"project_id" => Integer.to_string(project_id)}) | acc] end) 
      CncfDashboardApi.DataMigrations.upsert_from_map(
        CncfDashboardApi.Repo,
        pipeline_map_with_projects,
        CncfDashboardApi.SourceKeyPipelines,
        CncfDashboardApi.Pipelines,
        %{ref: :ref, 
          status: :status,
          sha: :sha,
          project_id: :project_id}
      )
    end
    )
  end

  def upsert_all_pipelines do
    source_key_projects = CncfDashboardApi.Repo.all(from skp in CncfDashboardApi.SourceKeyProjects) 
    project_ids = Enum.map(source_key_projects, fn(%{source_id: id}) -> %{"id" => String.to_integer(id)}end) 
      Logger.info fn ->
        "project_id take is: " <> inspect(project_ids)
      end
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_ids)
  end

  def upsert_pipeline_jobs(project_id, pipeline_id) do 
    pipeline_job_map = GitLabProxy.get_gitlab_pipeline_jobs(project_id, pipeline_id)
    CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      pipeline_job_map,
      CncfDashboardApi.SourceKeyPipelineJobs,
      CncfDashboardApi.PipelineJobs,
      %{name: :name, ref: :ref, 
        status: :status}
    )
  end 

  def upsert_all_pipeline_jobs do
    source_key_projects = CncfDashboardApi.Repo.all(from skp in CncfDashboardApi.SourceKeyProjects) 
    project_ids = Enum.map(source_key_projects, fn(%{source_id: id}) -> %{"id" => id}end) 
      Logger.info fn ->
        "project_id take is: " <> inspect(Enum.take(project_ids, 1))
      end
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(Enum.take(project_ids, 1))
  end
end
