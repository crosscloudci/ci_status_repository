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

  # pipeline_jobs depends on projects and pipelines being upserted previously
  def upsert_pipeline_jobs(source_project_id, source_pipeline_id) do 

    pipeline_job_map = GitLabProxy.get_gitlab_pipeline_jobs(source_project_id, source_pipeline_id)
    skp = CncfDashboardApi.Repo.get_by(CncfDashboardApi.SourceKeyProjects, 
                                       source_id: source_project_id |> Integer.to_string) 
    skpl = CncfDashboardApi.Repo.get_by(CncfDashboardApi.SourceKeyPipelines, 
                                        source_id: source_pipeline_id |> Integer.to_string) 
    # sproject_id = source_project_id |> Integer.to_string
    # spipeline_id = source_pipeline_id |> Integer.to_string
    # %{new_id: project_id} = CncfDashboardApi.Repo.all(
    #   from skp in 
    #   CncfDashboardApi.SourceKeyProjects, 
    #   where: skp.source_id == ^sproject_id ) 
    #   |> List.first
    #
    # %{new_id: pipeline_id} = CncfDashboardApi.Repo.all(
    #   from skp in 
    #   CncfDashboardApi.SourceKeyPipelines, 
    #   where: skp.source_id == ^spipeline_id) 
    #   |> List.first
    #
    if skp && skpl do
      pipeline_job_map_with_ids = Enum.reduce(pipeline_job_map, [], 
                                              fn (x,acc) -> 
                                                [Enum.into(x, %{"project_id" => Integer.to_string(skp.new_id)})
                                                |> Enum.into(%{"pipeline_id" => Integer.to_string(skpl.new_id)}) | acc] 
                                              end) 

      CncfDashboardApi.DataMigrations.upsert_from_map(
        CncfDashboardApi.Repo,
        pipeline_job_map_with_ids,
        CncfDashboardApi.SourceKeyPipelineJobs,
        CncfDashboardApi.PipelineJobs,
        %{name: :name, ref: :ref, 
          status: :status,
          project_id: :project_id,
          pipeline_id: :pipeline_id}
      )
    end
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
