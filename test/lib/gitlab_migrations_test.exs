require IEx;
defmodule CncfDashboardApi.GitlabMigrationsTest do
  use ExUnit.Case
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Projects
  alias CncfDashboardApi.Pipelines

  def projects do
    GitLabProxy.get_gitlab_projects()
  end

  test "save_project_names" do 
    projects = CncfDashboardApi.GitlabMigrations.save_project_names()
    assert 1 < CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
  end

  test "upsert_projects" do 
    # check insert 
    upsert_count = CncfDashboardApi.GitlabMigrations.upsert_projects()
    project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
    assert 1 < upsert_count  
    assert 1 < project_count  
    assert 1 < source_project_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_projects()
    assert project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    assert source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
  end

  @tag timeout: 120_000 
  test "upsert_pipelines" do 
    # check insert 
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(Enum.take(projects(), 1))
    pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
    assert 1 < pipeline_count  
    assert 1 < source_pipeline_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_pipelines(Enum.take(projects(), 1))
    assert pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Pipelines, :count, :id)  
    assert source_pipeline_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelines, :count, :id)  
  end

  test "upsert_pipeline_jobs" do 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(1, 1)
    pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
    assert 1 < pipeline_jobs_count  
    assert 1 < source_pipeline_jobs_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(1, 1)
    assert pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.PipelineJobs, :count, :id)  
    assert source_pipeline_jobs_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyPipelineJobs, :count, :id)  
  end
end
