require IEx;
require CncfDashboardApi.DataMigrations;
require Logger;
defmodule CncfDashboardApi.GitlabMigrationsTest do
  import Ecto.Query
  use EctoConditionals, repo: CncfDashboardApi.Repo
  use ExUnit.Case
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Projects
  alias CncfDashboardApi.Pipelines

  def projects do
    pjs = GitLabProxy.get_gitlab_projects()
    Enum.take(pjs, 2)
  end

  def test_project_id do
    1
  end

  def test_pipeline_id do
    1
  end

  test "save_project_names" do 
    projects = CncfDashboardApi.GitlabMigrations.save_project_names()
    assert 1 < CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
  end
  #
  test "upsert_clouds" do 
    # check insert 
    {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    cloud_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Clouds, :count, :id)  
    assert 1 < upsert_count  
    assert 1 < cloud_count  
    # check update -- should not increase
    {:ok, upsert, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    assert cloud_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Clouds, :count, :id)  
  end

  test "upsert_projects" do 
    # check insert 
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
    assert 1 < upsert_count  
    assert 1 < project_count  
    assert 1 < source_project_count
    # check update -- should not increase
    {:ok, upsert, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    assert project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    assert source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
  end

  test "upsert_project (singular)" do 
    # check insert 
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_project(test_project_id)
    project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
    assert 1 = upsert_count  
    assert 1 = project_count  
    assert 1 = source_project_count
    # check update -- should not increase
    {:ok, upsert, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    assert project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    assert source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
  end

  test "upsert_yml_projects" do 
    # check insert 
    # {:ok, _, _} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    # need all the projects to test the yml
    project_map = GitLabProxy.get_gitlab_projects()

    upsert_count = CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      project_map,
      CncfDashboardApi.SourceKeyProjects,
      CncfDashboardApi.Projects,
      %{name: :name}
    )
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_yml_projects()
    assert 1 < upsert_count  
  end

  @tag timeout: 320_000 
  @tag :wip
  test "upsert_pipelines" do 
    # check insert 
    {:ok, upsert_count, project_map_orig} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    project_map = project_map_orig |> Enum.reduce([], fn(x, acc) -> 
      # Logger.info fn ->
        #   "project_map_orig project: #{inspect(x)}"
        # end
        # cross project, cross-cloud have too many pipelines 
        # for test to retrieve
        case x["name"] do
          n when n in ["cross-project", "cross-cloud"] ->
            acc
          _ -> 
            [x|acc]
        end
    end)
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_map)
    pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
    assert 1 < pipeline_count  
    assert 1 < source_pipeline_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_map)
    assert pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    assert source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
  end

  @tag timeout: 360_000 
  @tag :wip
  test "upsert_pipeline (singular)" do 
    # check insert 
    {:ok, upsert_count, project_map_orig} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    project_map = project_map_orig |> Enum.reduce([], fn(x, acc) -> 
      # Logger.info fn ->
        #   "project_map_orig project: #{inspect(x)}"
        # end
        # cross project, cross-cloud have too many pipelines 
        # for test to retrieve
        case x["name"] do
          n when n in ["cross-project", "cross-cloud"] ->
            acc
          _ -> 
            [x|acc]
        end
    end)
    # get first project with a pipeline
    project = Enum.find(project_map, fn(x) ->
      count = GitLabProxy.get_gitlab_pipelines(x["id"]) 
      |> Enum.count 
      count > 0
    end)
    # project = project_map |> List.first 
    pipeline_map = GitLabProxy.get_gitlab_pipelines(project["id"])
    pipeline = pipeline_map |> List.first 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline( project["id"] |> Integer.to_string, pipeline["id"] |> Integer.to_string)
    pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
    assert 1 = pipeline_count  
    assert 1 = source_pipeline_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_map)
    assert pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    assert source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
  end

  @tag timeout: 320_000 
  @tag :wip
  test "upsert_pipeline_jobs" do 
    # CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(test_project_id, test_pipeline_id)
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_map)
    # get first project with a pipeline
    project = Enum.find(project_map, fn(x) ->
      count = GitLabProxy.get_gitlab_pipelines(x["id"]) 
      |> Enum.count 
      count > 0
    end)
    pipeline_map = GitLabProxy.get_gitlab_pipelines(project["id"])
    pipeline = pipeline_map |> List.first 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs( project["id"], pipeline["id"])
    pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
    assert 0 < pipeline_jobs_count  
    assert 0 < source_pipeline_jobs_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(test_project_id, test_pipeline_id)
    assert pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    assert source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
  end

  @tag timeout: 320_000 
  @tag :wip
  test "upsert_missing_target_project_pipeline" do 
    # check insert 
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    # get first project with a pipeline
    project = Enum.find(project_map, fn(x) ->
      count = GitLabProxy.get_gitlab_pipelines(x["id"]) 
      |> Enum.count 
      count > 0
    end)
    if is_nil(project) do
      raise "no projects with pipelines"
    end
    # project = project_map |> List.first 
    pipeline_map = GitLabProxy.get_gitlab_pipelines(project["id"])
    pipeline = pipeline_map |> List.first 
    # CncfDashboardApi.GitlabMigrations.upsert_pipeline( project["id"] |> Integer.to_string, pipeline["id"] |> Integer.to_string)
    CncfDashboardApi.GitlabMigrations.upsert_missing_target_project_pipeline( project["name"], pipeline["id"] |> Integer.to_string)
    pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
    assert 1 = pipeline_count  
    assert 1 = source_pipeline_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_map)
    assert pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    assert source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
  end
end
