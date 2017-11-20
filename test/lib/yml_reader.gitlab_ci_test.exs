require IEx;
defmodule CncfDashboardApi.YmlReader.GitlabCiTest do
  use ExUnit.Case

  test "get" do 
    yml = CncfDashboardApi.YmlReader.GitlabCi.get()
    assert yml |> is_binary  
  end

  test "cloud_list" do 
    cloud_list = CncfDashboardApi.YmlReader.GitlabCi.cloud_list()
    assert Enum.find_value(cloud_list, fn(x) -> x["cloud_name"] == "AWS" end) 
    assert Enum.find_value(cloud_list, fn(x) -> x["active"] == true end) 
  end

  @tag :wip
  test "project_list" do 
    project_list = CncfDashboardApi.YmlReader.GitlabCi.project_list()
    assert Enum.find_value(project_list, fn(x) -> x["yml_name"] == "kubernetes" end) 
    assert Enum.find_value(project_list, fn(x) -> x["active"] == true end) 
    # assert Enum.find_value(project_list, fn(x) -> x["logo_url"] == "https://raw.githubusercontent.com/cncf/artwork/master/kubernetes/logo.png" end) 
    assert Enum.find_value(project_list, fn(x) -> x["display_name"] == "Kubernetes" end) 
    assert Enum.find_value(project_list, fn(x) -> x["sub_title"] == "Orchestration" end) 
    assert Enum.find_value(project_list, fn(x) -> x["yml_gitlab_name"] == "Kubernetes" end) 
    assert Enum.find_value(project_list, fn(x) -> x["order"] == 1 end) 
    assert Enum.find_value(project_list, fn(x) -> x["repository_url"] == "https://gitlab.dev.cncf.ci/prometheus/prometheus" end) 
    assert Enum.find_value(project_list, fn(x) -> x["timeout"] == 900 end) 
    assert Enum.find_value(project_list, fn(x) -> x["project_url"] == "https://github.com/kubernetes/kubernetes" end) 
  end
end
