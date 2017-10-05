defmodule CncfDashboardApi.SchedulerTest do
  use ExUnit.Case
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Projects

  test "save_project_names" do 
    projects = CncfDashboardApi.Scheduler.save_project_names()
    assert 1 < CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
  end

  test "upsert_projects" do 
    projects = CncfDashboardApi.Scheduler.upsert_projects()
    assert 1 < CncfDashboardApi.Repo.aggregate(CncfDashboardApi.Projects, :count, :id)  
  end
end
