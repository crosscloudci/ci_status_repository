defmodule CncfDashboardApi.SchedulerTest do
  use ExUnit.Case
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Projects

  test "save_projects" do 
    projects = CncfDashboardApi.Scheduler.save_projects()
    assert 2 > CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
  end

  # test "get_gitlab_pipelines" do 
  #   pipelines = RubyElixir.GitLabProxy.get_gitlab_pipelines(CncfDashboardApi.GitLabProxyTest.project_id)
  #   assert true = is_list(pipelines)
  # end
end
