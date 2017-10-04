defmodule CncfDashboardApi.GitLabProxyTest do
  use ExUnit.Case

  def project_id do
    "18"
	end

  test "get_gitlab_projects" do 
    projects = RubyElixir.GitLabProxy.get_gitlab_projects 
    assert true = is_list(projects)
  end

  test "get_gitlab_pipelines" do 
    pipelines = RubyElixir.GitLabProxy.get_gitlab_pipelines(CncfDashboardApi.GitLabProxyTest.project_id)
    assert true = is_list(pipelines)
  end
end
