require Logger;
require IEx;
defmodule CncfDashboardApi.GitLabProxyTest do
  use ExUnit.Case

  def project_id do
    # projects = GitLabProxy.get_gitlab_projects 
    # %{"id" => a } = List.first(projects)
    # a 
    "1"
	end

  def pipeline_id do
    "1"
	end

  test "get_gitlab_project_names" do 
    projects = GitLabProxy.get_gitlab_project_names 
    assert true = is_list(projects)
  end

  test "get_gitlab_projects" do 
    projects = GitLabProxy.get_gitlab_projects 
      Logger.info fn ->
        "test: projects: #{inspect(projects)}"
      end
    assert %{"id" => a } = List.first(projects)
  end

  test "get_gitlab_project" do 
    project = GitLabProxy.get_gitlab_project(project_id)
      Logger.info fn ->
        "test: project: #{inspect(project)}"
      end
    assert %{"id" => a } = project
  end

  test "get_gitlab_pipeline" do 
    pipeline = GitLabProxy.get_gitlab_pipeline(CncfDashboardApi.GitLabProxyTest.project_id, 
                                               CncfDashboardApi.GitLabProxyTest.pipeline_id)
    assert %{"id" => a } = pipeline
  end

  test "get_gitlab_pipelines" do 
    pipelines = GitLabProxy.get_gitlab_pipelines(CncfDashboardApi.GitLabProxyTest.project_id)
    assert %{"id" => a } = List.first(pipelines)
  end

  test "get_gitlab_pipeline_jobs" do 
    pipelines = GitLabProxy.get_gitlab_pipeline_jobs(CncfDashboardApi.GitLabProxyTest.project_id, CncfDashboardApi.GitLabProxyTest.pipeline_id)
    assert %{"commit" => %{} } = List.first(pipelines)
  end
end
