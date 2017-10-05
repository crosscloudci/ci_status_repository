require Logger;
require IEx;
defmodule CncfDashboardApi.GitLabProxyTest do
  use ExUnit.Case

  def project_id do
    "1"
	end

  test "get_gitlab_project_names" do 
    projects = RubyElixir.GitLabProxy.get_gitlab_project_names 
    assert true = is_list(projects)
  end

  test "get_gitlab_projects" do 
    projects = RubyElixir.GitLabProxy.get_gitlab_projects 
    IEx.pry
      Logger.info fn ->
        "test: projects: #{inspect(projects)}"
      end
    assert true = is_list(projects)
  end

  test "get_gitlab_pipelines" do 
    pipelines = RubyElixir.GitLabProxy.get_gitlab_pipelines(CncfDashboardApi.GitLabProxyTest.project_id)
    assert true = is_list(pipelines)
  end
end
