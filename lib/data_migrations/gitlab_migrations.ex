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
    cloud_map = CncfDashboardApi.YmlReader.GitlabCi.cloud_list() |> Enum.reduce([], fn(x, acc) -> 
      local_cloud = CncfDashboardApi.Repo.all(from p in CncfDashboardApi.Clouds, 
                                                where: p.cloud_name == ^x["cloud_name"])
                                                |> List.first
                                   
      if local_cloud do  
        [%{x | "id" => local_cloud.id} | acc] 
      else
        [x|acc]
      end
    end)

    upsert_count = CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      cloud_map,
      false,
      CncfDashboardApi.Clouds,
      %{ cloud_name: :cloud_name,
        active: :active,
        display_name: :display_name,
        order: :order}
    )
    {:ok, upsert_count, cloud_map}
  end

  # need to upsert projects before yml projects
	def upsert_yml_projects do
    # need to pull local ids into the project map
    # Logger.info fn ->
    #   "upsert_yml_projects project_list before update: #{inspect(CncfDashboardApi.YmlReader.GitlabCi.project_list())}"
    # end
    # Logger.info fn ->
    #   "upsert_yml_projects saved projects before update: #{inspect(CncfDashboardApi.Repo.all(CncfDashboardApi.Projects))}"
    # end
    project_map = CncfDashboardApi.YmlReader.GitlabCi.project_list() |> Enum.reduce([], fn(x, acc) -> 
      local_project = CncfDashboardApi.Repo.all(from p in CncfDashboardApi.Projects, 
                                                where: p.name == ^x["yml_gitlab_name"])
                                                |> List.first
                                   
      if local_project do  
        [%{x | "id" => local_project.id} | acc] 
      else
        acc
      end
    end)
    # Logger.info fn ->
    #   "upsert_yml_projects project_map before update: #{inspect(project_map)}"
    # end
    upsert_count = CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      project_map,
      false,
      CncfDashboardApi.Projects,
      %{id: :id,
        yml_name: :yml_name,
        active: :active,
        logo_url: :logo_url,
        display_name: :display_name,
        sub_title: :sub_title,
        yml_gitlab_name: :yml_gitlab_name,
        project_url: :project_url,
        repository_url: :repository_url,
        timeout: :timeout,
        cncf_relation: :cncf_relation,
        order: :order,
      }
    )
    {:ok, upsert_count, project_map}
  end

  def upsert_project(source_project_id) do
    project_map_orig = GitLabProxy.get_gitlab_project(source_project_id)
    upsert_projects([project_map_orig])
  end

  def upsert_missing_target_project_pipeline(source_project_name, source_pipeline_id) do
    Logger.info fn ->
      "upsert_missing_target_project_pipeline: source_project_name, source_pipeline_id : #{inspect(source_project_name)}, #{inspect(source_pipeline_id)}"
    end
    upsert_projects
    p_record = CncfDashboardApi.Repo.all(from p in CncfDashboardApi.Projects, 
                                         where: ilike(p.name, ^"#{source_project_name}")) |> List.first
    Logger.info fn ->
      "upsert_missing_target_project_pipeline: p_record : #{inspect(p_record)}"
    end
    if is_nil(p_record) do
      p_found = false
    else
      p_found = true
    end
    if p_found do
      {skp_found, skp_record} = %CncfDashboardApi.SourceKeyProjects{new_id: p_record.id } |> find_by([:new_id])
      Logger.info fn ->
        "upsert_missing_target_project_pipeline: skp_record: #{inspect(skp_record)}"
      end
      upsert_pipeline(skp_record.source_id, source_pipeline_id)
      {:ok, _upsert_count, pipeline_map} = CncfDashboardApi.GitlabMigrations.upsert_pipeline(skp_record.source_id, source_pipeline_id) 
      Logger.info fn ->
        "upsert_missing_target_project_pipeline: pipeline_map: #{inspect(pipeline_map)}"
      end
    else
      Logger.error fn ->
        "upsert_missing_target_project_pipeline: project not found}"
      end

    end
  end

  def upsert_projects do
    project_map_orig = GitLabProxy.get_gitlab_projects()
    upsert_projects(project_map_orig)
	end

  def upsert_projects(map) do
    project_map_orig = map
    if Mix.env == :test do
      # ccp = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == "cross-cloud" end)
      # Needs to return at least one project with pipelines
      # test_project_map = project_map_orig |> Enum.reduce([], fn(x, acc) -> 
      #   # Logger.info fn ->
      #   #   "project_map_orig project: #{inspect(x)}"
      #   # end
      #   # cross project, cross-cloud have too many pipelines 
      #   # for test to retrieve
      #   case x["name"] do
      #     n when n in ["cross-project", "cross-cloud"] ->
      #       acc
      #     _ -> 
      #       [x|acc]
      #   end
      # end)
      # take_project_map =  Enum.take(test_project_map, 3)
      take_project_map =  Enum.take(project_map_orig, 2)
      # take_project_map =  Enum.take(project_map_orig, 5)
      # project_map = take_project_map ++ [ccp]
      project_map = take_project_map
    else
      project_map = project_map_orig 
    end

    upsert_count = CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      project_map,
      CncfDashboardApi.SourceKeyProjects,
      CncfDashboardApi.Projects,
      %{name: :name,
        web_url: :web_url,
        ssh_url_to_repo: :ssh_url_to_repo,
        http_url_to_repo: :http_url_to_repo }
    )
    {:ok, upsert_count, project_map}
  end

  # must be called after project already upserted
  def upsert_pipeline(source_project_id, source_pipeline_id) do
    skp = CncfDashboardApi.Repo.get_by(CncfDashboardApi.SourceKeyProjects, source_id: source_project_id) 
    # put local project id in the pipeline upsert
    pipeline_map = GitLabProxy.get_gitlab_pipeline(source_project_id, source_pipeline_id)
    pipeline_map_with_project = Enum.reduce([pipeline_map], [], fn (x,acc) -> [Enum.into(x, %{"project_id" => Integer.to_string(skp.new_id)}) | acc] end) 
    upsert_count =CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      pipeline_map_with_project,
      CncfDashboardApi.SourceKeyPipelines,
      CncfDashboardApi.Pipelines,
      %{ref: :ref, 
        status: :status,
        sha: :sha,
        project_id: :project_id}
    )
    {:ok, upsert_count, pipeline_map_with_project}
  end

  def upsert_pipelines(source_projects) do
    Enum.map(source_projects, fn (%{"id" => source_project_id}) ->
      # Logger.info fn ->
      #   "source_project_id is: " <> inspect(source_project_id)
      # end
      pipeline_map = GitLabProxy.get_gitlab_pipelines(source_project_id)
      # get the local project ids from the project list
      skp = CncfDashboardApi.Repo.get_by(CncfDashboardApi.SourceKeyProjects, source_id: source_project_id |> Integer.to_string) 
      # put local project id in the pipeline upsert
      pipeline_map_with_projects = Enum.reduce(pipeline_map, [], fn (x,acc) -> [Enum.into(x, %{"project_id" => Integer.to_string(skp.new_id)}) | acc] end) 
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
      source_key_projects =  Enum.take(source_key_projects_orig, 2) # limited in test mode for speed purposes.
    else
      source_key_projects = source_key_projects_orig
    end
    project_ids = Enum.map(source_key_projects, fn(%{source_id: id}) -> %{"id" => String.to_integer(id)}end) 
    # Logger.info fn ->
    #   "upsert_all_piplelines project_ids are: " <> inspect(project_ids)
    # end
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_ids) 
  end 

  # pipeline_jobs depends on projects and pipelines being upserted previously
  def upsert_pipeline_jobs(source_project_id, source_pipeline_id) do 

    pipeline_job_map_orig = GitLabProxy.get_gitlab_pipeline_jobs(source_project_id, source_pipeline_id)
    if Mix.env == :test do
      pipeline_job_map =  Enum.take(pipeline_job_map_orig, 4) # limited in test mode for speed purposes. 
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
      # Logger.info fn ->
      #   "Either Source key project or pipeline is nil"
      # end
    end
  end 

  # pipeline_jobs depends on projects and pipelines being upserted previously
  def upsert_all_pipeline_jobs do
    # Logger.info fn ->
    #   "upsert_all_pipeline_jobs"
    # end
    #
    pl = Ecto.Query.from pl in CncfDashboardApi.Pipelines, 
      join: skpl in CncfDashboardApi.SourceKeyPipelines, on: skpl.new_id == pl.id,
      join: p in CncfDashboardApi.Projects, on: p.id == pl.project_id,
      join: skp in CncfDashboardApi.SourceKeyProjects, on: skp.new_id == p.id,
      select: {p, pl, skpl, skp}
    project_pipelines = CncfDashboardApi.Repo.all(pl) 
    # Logger.info fn ->
    #   "upsert_all_pipeline_jobs count: " <> inspect(project_pipelines)
    # end
    Enum.map(project_pipelines, fn({project, pipeline, skpipeline, skproject}) ->
      # Logger.info fn ->
      #   "load all pipeline jobs: source_project_id: " <> inspect(skproject.source_id) <> 
      #     " load all pipeline jobs: source_pipeline_id: " <> inspect(skpipeline.source_id)
      # end
      CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(skproject.source_id |> String.to_integer, 
                                                             skpipeline.source_id |> String.to_integer)
    end)
  end
end
