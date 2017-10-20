require IEx;
defmodule CncfDashboardApi.GitlabMigrationsTest do
  use ExUnit.Case
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Projects
  alias CncfDashboardApi.Pipelines

  def projects do
    pjs = GitLabProxy.get_gitlab_projects()
    Enum.take(pjs, 3)
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

  @tag timeout: 120_000 
  test "upsert_pipelines" do 
    # check insert 
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
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

  @tag timeout: 320_000 
  test "upsert_pipeline_jobs" do 
    # CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(test_project_id, test_pipeline_id)
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_projects()
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(project_map)
    project = project_map |> List.first 
    pipeline_map = GitLabProxy.get_gitlab_pipelines(project["id"])
    pipeline = pipeline_map |> List.first 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs( project["id"], pipeline["id"])
    pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
    assert 1 < pipeline_jobs_count  
    assert 1 < source_pipeline_jobs_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(test_project_id, test_pipeline_id)
    assert pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    assert source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
  end
end
