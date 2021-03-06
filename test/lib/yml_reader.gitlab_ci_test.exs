require IEx;
# require Logger;
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
          # Logger.info fn ->
          #   "env variable: #{inspect(System.get_env("PROJECT_SEGMENT_ENV"))}"
          # end
          yml = CncfDashboardApi.YmlReader.GitlabCi.configuration_repo_path(v["configuration_repo"]) |> CncfDashboardApi.YmlReader.GitlabCi.getcncfci() 
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

  test "cncf relation list" do 
    cncf_relations = CncfDashboardApi.YmlReader.GitlabCi.cncf_relations_list()
    assert Enum.find_value(cncf_relations, fn(x) -> 
      x["name"] == "Graduated" &&
      x["order"] == 1 
    end) 
  end

  @tag :wip
  test "projects_with_ymls" do 
    project_list = CncfDashboardApi.YmlReader.GitlabCi.projects_with_yml()
    # assert Enum.find_value(project_list, fn(x) -> x["project_name"] == "prometheus" end) 
    assert Enum.find_value(project_list, fn(x) -> x["project_name"] == "coredns" end) 
  end

  @tag :wip
  test "coredns_project_list" do 
    full_project_list = CncfDashboardApi.YmlReader.GitlabCi.project_list()

    project_list = Enum.reduce(full_project_list, [], fn (x, acc) -> 
      case x["yml_name"] do
        "coredns" -> [x | acc]
        _ -> acc 
      end 
    end)

    assert Enum.find_value(project_list, fn(x) -> x["yml_name"] == "coredns" end) 
    assert Enum.find_value(project_list, fn(x) -> x["active"] == true end) 
    assert Enum.find_value(project_list, fn(x) -> x["display_name"] == "CoreDNS" end) 
    assert Enum.find_value(project_list, fn(x) -> x["sub_title"] == "Service Discovery" end) 
    assert Enum.find_value(project_list, fn(x) -> x["stable_ref"] == "v1.5.0" end) 
    assert Enum.find_value(project_list, fn(x) -> x["head_ref"] == "master" end) 
    assert Enum.find_value(project_list, fn(x) -> x["yml_gitlab_name"] == "coredns" end) 
    assert Enum.find_value(project_list, fn(x) -> x["cncf_relation"] == "Graduated" end) 
    assert Enum.find_value(project_list, fn(x) -> x["order"] == 2 end) 
    assert Enum.find_value(project_list, fn(x) -> x["repository_url"] == "https://github.com/coredns/coredns" end) 
    assert Enum.find_value(project_list, fn(x) -> is_number(x["timeout"]) end) 
    assert Enum.find_value(project_list, fn(x) -> x["project_url"] == "https://github.com/coredns/coredns" end) 
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
