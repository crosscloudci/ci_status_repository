require Logger;
require IEx;
require CncfDashboardApi.DataMigrations;
defmodule CncfDashboardApi.GitlabMigrations do
  use EctoConditionals, repo: CncfDashboardApi.Repo

	def save_project_names do
		projects = GitLabProxy.get_gitlab_project_names
		Enum.map(projects, fn(source_project) -> 

			prec = %CncfDashboardApi.Projects{name: source_project} 
			CncfDashboardApi.Repo.insert(prec) 
		end) 
  end

	def upsert_projects do
    project_map = GitLabProxy.get_gitlab_projects
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
      pipeline_map = GitLabProxy.get_gitlab_pipelines(project_id)
      CncfDashboardApi.DataMigrations.upsert_from_map(
        CncfDashboardApi.Repo,
        pipeline_map,
        CncfDashboardApi.SourceKeyPipelines,
        CncfDashboardApi.Pipelines,
        %{ref: :ref, 
        status: :status}
      )
    end
    )
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
end
