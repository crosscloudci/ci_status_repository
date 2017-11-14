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

	def upsert_clouds do
    cloud_map = CncfDashboardApi.YmlReader.GitlabCi.cloud_list()

    upsert_count = CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      cloud_map,
      false,
      CncfDashboardApi.Clouds,
      %{cloud_name: :cloud_name,
        active: :active,
        order: :order}
    )
    {:ok, upsert_count, cloud_map}
  end

	def upsert_yml_projects do
    # need to pull local ids into the prject map
    project_map = CncfDashboardApi.YmlReader.GitlabCi.project_list()
    |> Enum.reduce([], fn(x, acc) -> 
      local_project = CncfDashboardApi.Repo.all(from p in CncfDashboardApi.Projects, 
                                                where: p.name == ^x["yml_gitlab_name"])
                                                |> List.first
                                   
      if local_project do  
        [%{x | "id" => local_project.id} | acc] 
      else
        acc
      end
    end)
    upsert_count = CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      project_map,
      false,
      CncfDashboardApi.Projects,
      %{yml_name: :yml_name,
        active: :active,
        logo_url: :logo_url,
        display_name: :display_name,
        sub_title: :sub_title,
        yml_gitlab_name: :yml_gitlab_name,
        order: :order,
      }
    )
    {:ok, upsert_count, project_map}
  end

  def upsert_single_project(source_project_id) do
    project_map_orig = GitLabProxy.get_gitlab_projects()
  end
  def upsert_projects(map) do
    project_map_orig = GitLabProxy.get_gitlab_projects()
    if Mix.env == :test do
      project_map =  Enum.take(project_map_orig, 2)
    else
      project_map = project_map_orig 
    end

    upsert_count = CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      project_map,
      CncfDashboardApi.SourceKeyProjects,
      CncfDashboardApi.Projects,
      %{name: :name}
    )
    {:ok, upsert_count, project_map}
  end

  def upsert_pipelines(source_projects) do
    Enum.map(source_projects, fn (%{"id" => source_project_id}) ->
      Logger.info fn ->
        "source_project_id is: " <> inspect(source_project_id)
      end
      pipeline_map = GitLabProxy.get_gitlab_pipelines(source_project_id)
      skp = CncfDashboardApi.Repo.get_by(CncfDashboardApi.SourceKeyProjects, 
                                         source_id: source_project_id |> Integer.to_string) 
                                         pipeline_map_with_projects = Enum.reduce(pipeline_map, [], 
                                                                                  fn (x,acc) -> 
                                                                                    [Enum.into(x, %{"project_id" => Integer.to_string(skp.new_id)}) | acc] 
                                                                                  end) 
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
    source_key_projects_orig = CncfDashboardApi.Repo.all(from skp in CncfDashboardApi.SourceKeyProjects) 
    if Mix.env == :test do
      source_key_projects =  Enum.take(source_key_projects_orig, 2)
    else
      source_key_projects = source_key_projects_orig
    end
    project_ids = Enum.map(source_key_projects, fn(%{source_id: id}) -> %{"id" => String.to_integer(id)}end) 
    Logger.info fn ->
      "upsert_all_piplelines project_ids are: " <> inspect(project_ids)
    end
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_ids) 
  end 

  # pipeline_jobs depends on projects and pipelines being upserted previously
  def upsert_pipeline_jobs(source_project_id, source_pipeline_id) do 

    pipeline_job_map_orig = GitLabProxy.get_gitlab_pipeline_jobs(source_project_id, source_pipeline_id)
    if Mix.env == :test do
      pipeline_job_map =  Enum.take(pipeline_job_map_orig, 2)
    else
      pipeline_job_map = pipeline_job_map_orig
    end
    skp = CncfDashboardApi.Repo.get_by(CncfDashboardApi.SourceKeyProjects, 
                                       source_id: source_project_id |> Integer.to_string) 
    skpl = CncfDashboardApi.Repo.get_by(CncfDashboardApi.SourceKeyPipelines, 
                                        source_id: source_pipeline_id |> Integer.to_string) 
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
    else
      Logger.info fn ->
        "Either Source key project or pipeline is nil"
      end
    end
  end 

  # pipeline_jobs depends on projects and pipelines being upserted previously
  def upsert_all_pipeline_jobs do
    Logger.info fn ->
      "upsert_all_pipeline_jobs"
    end
    # TODO 1. loop through all projects that exist remotely
    # TODO 2. loop through each pipeline that exists for each project
    # TODO 3. get the local id for the project
    # TODO 4. get the local id for the pipleline
    #
    pl = Ecto.Query.from pl in CncfDashboardApi.Pipelines, 
      join: skpl in CncfDashboardApi.SourceKeyPipelines, on: skpl.new_id == pl.id,
      join: p in CncfDashboardApi.Projects, on: p.id == pl.project_id,
      join: skp in CncfDashboardApi.SourceKeyProjects, on: skp.new_id == p.id,
      select: {p, pl, skpl, skp}
    project_pipelines = CncfDashboardApi.Repo.all(pl) 
    Logger.info fn ->
      "upsert_all_pipeline_jobs count: " <> inspect(project_pipelines)
    end
    Enum.map(project_pipelines, fn({project, pipeline, skpipeline, skproject}) ->
      Logger.info fn ->
        "load all pipeline jobs: source_project_id: " <> inspect(skproject.source_id) <> 
          " load all pipeline jobs: source_pipeline_id: " <> inspect(skpipeline.source_id)
      end
      CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(skproject.source_id |> String.to_integer, 
                                                             skpipeline.source_id |> String.to_integer)
    end)
  end
end
