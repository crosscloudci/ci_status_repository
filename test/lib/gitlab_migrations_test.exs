defmodule CncfDashboardApi.GitlabMigrationsTest do
  use ExUnit.Case
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Projects

  test "save_project_names" do 
    projects = CncfDashboardApi.GitlabMigrations.save_project_names()
    assert 1 < CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
  end

  test "upsert_projects" do 
    # check insert 
    CncfDashboardApi.GitlabMigrations.upsert_projects()
    project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
    assert 1 < project_count  
    assert 1 < source_project_count
    # check update -- should not increase
    CncfDashboardApi.GitlabMigrations.upsert_projects()
    assert project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
    assert source_project_count = CncfDashboardApi.Repo.aggregate(CncfDashboardApi.SourceKeyProjects, :count, :id)  
  end
end
