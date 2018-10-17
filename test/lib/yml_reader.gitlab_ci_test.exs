require IEx;
defmodule CncfDashboardApi.YmlReader.GitlabCiTest do
  use ExUnit.Case

  test "get" do 
    yml = CncfDashboardApi.YmlReader.GitlabCi.get()
    assert yml |> is_binary  
  end

  test "cloud_list" do 
    cloud_list = CncfDashboardApi.YmlReader.GitlabCi.cloud_list()
    assert Enum.find_value(cloud_list, fn(x) -> x["cloud_name"] == "aws" end) 
    assert Enum.find_value(cloud_list, fn(x) -> x["active"] == true end) 
  end

  test "project_list" do 
    project_list = CncfDashboardApi.YmlReader.GitlabCi.project_list()
    assert Enum.find_value(project_list, fn(x) -> x["yml_name"] == "kubernetes" end) 
    assert Enum.find_value(project_list, fn(x) -> x["active"] == true end) 
    assert Enum.find_value(project_list, fn(x) -> x["display_name"] == "Kubernetes" end) 
    assert Enum.find_value(project_list, fn(x) -> x["sub_title"] == "Orchestration" end) 
    assert Enum.find_value(project_list, fn(x) -> x["yml_gitlab_name"] == "Kubernetes" end) 
    assert Enum.find_value(project_list, fn(x) -> x["order"] == 1 end) 
    assert Enum.find_value(project_list, fn(x) -> x["repository_url"] == "https://github.com/kubernetes/kubernetes" end) 
    assert Enum.find_value(project_list, fn(x) -> is_number(x["timeout"]) end) 
    assert Enum.find_value(project_list, fn(x) -> x["project_url"] == "https://github.com/kubernetes/kubernetes" end) 
  end

  test "gitlab_pipeline_config" do 
    cloud_list = CncfDashboardApi.YmlReader.GitlabCi.gitlab_pipeline_config()
    assert Enum.find_value(cloud_list, fn(x) -> x["pipeline_name"] == "cross-project" end) 
    assert Enum.find_value(cloud_list, fn(x) -> x["pipeline_name"] == "cross-cloud" end) 
    assert Enum.find_value(cloud_list, fn(x) -> x["pipeline_name"] == "project" end) 
    assert Enum.find_value(cloud_list, fn(x) -> is_number(x["timeout"]) end) 
    # assert Enum.find_value(cloud_list, fn(x) -> x["status_jobs"] == ["e2e", "App-Deploy"] end) 
    assert Enum.find_value(cloud_list, fn(x) -> x["status_jobs"] == ["Build-Source", "App-Deploy", "e2e"] end) 
  end
end
