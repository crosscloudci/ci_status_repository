defmodule CncfDashboardApi.GitLabProxyTest do
  use ExUnit.Case

  test "get_gitlab_projects" do 
    projects = RubyElixir.GitLabProxy.get_gitlab_projects 
    assert true = is_list(projects)
  end
end
