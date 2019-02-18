require IEx;
defmodule CncfDashboardApi.YmlReader.GitlabCiTest do
  use ExUnit.Case

  test "get" do 
    yml = CncfDashboardApi.YmlReader.GitlabCi.get()
    assert yml |> is_binary  
  end

  @tag :wip
  test "getcncfci" do 
		yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
		yml["projects"] 
		|> Stream.with_index 
    |> Enum.reduce([], fn ({{k, v}, idx}, acc) -> 
      case k do
        "prometheus" ->
          yml = CncfDashboardApi.YmlReader.GitlabCi.getcncfci(v["configuration_repo"])
          assert yml |> is_binary  
        _ ->
      end
		end) 
  end

  test "cloud_list" do 
    cloud_list = CncfDashboardApi.YmlReader.GitlabCi.cloud_list()
    assert Enum.find_value(cloud_list, fn(x) -> x["cloud_name"] == "aws" end) 
    assert Enum.find_value(cloud_list, fn(x) -> x["active"] == true end) 
  end

  @tag :wip
  test "projects_with_ymls" do 
    project_list = CncfDashboardApi.YmlReader.GitlabCi.projects_with_yml()
    assert Enum.find_value(project_list, fn(x) -> x["project_name"] == "prometheus" end) 
  end

  @tag :wip
  test "prometheus_project_list" do 
    full_project_list = CncfDashboardApi.YmlReader.GitlabCi.project_list()

    project_list = Enum.reduce(full_project_list, [], fn (x, acc) -> 
      case x["yml_name"] do
        "prometheus" -> [x | acc]
        _ -> acc 
      end 
    end)

    assert Enum.find_value(project_list, fn(x) -> x["yml_name"] == "prometheus" end) 
    assert Enum.find_value(project_list, fn(x) -> x["active"] == true end) 
    assert Enum.find_value(project_list, fn(x) -> x["display_name"] == "Prometheus" end) 
    assert Enum.find_value(project_list, fn(x) -> x["sub_title"] == "Monitoring" end) 
    assert Enum.find_value(project_list, fn(x) -> x["yml_gitlab_name"] == "prometheus" end) 
    assert Enum.find_value(project_list, fn(x) -> x["order"] == 2 end) 
    assert Enum.find_value(project_list, fn(x) -> x["repository_url"] == "https://github.com/prometheus/prometheus" end) 
    assert Enum.find_value(project_list, fn(x) -> is_number(x["timeout"]) end) 
    assert Enum.find_value(project_list, fn(x) -> x["project_url"] == "https://github.com/prometheus/prometheus" end) 
    assert Enum.find_value(project_list, fn(x) -> Map.has_key?(x,"logo_url") end)  
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
    assert Enum.find_value(project_list, fn(x) -> Map.has_key?(x,"logo_url") end)  
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
