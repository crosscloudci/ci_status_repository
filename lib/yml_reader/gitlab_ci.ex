require IEx;
defmodule CncfDashboardApi.YmlReader.GitlabCi do
	def get do
		Application.ensure_all_started :inets

    {:ok, resp} = :httpc.request(:get, {System.get_env("GITLAB_CI_YML") |> to_charlist, []}, [], [body_format: :binary])
		{{_, 200, 'OK'}, _headers, body} = resp
    body
  end
  def cloud_list do
    yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
    # yml["variables"]["ACTIVE_CLOUDS"] 
    # |> String.split(",")
    # |> Stream.with_index 
    # |> Enum.reduce([], fn ({x,idx},acc) -> [%{"id" => idx, "cloud_name" => x} | acc] end)
    yml["clouds"] 
    |> Stream.with_index 
    |> Enum.reduce([], fn ({{k, v}, idx}, acc) -> 
      [%{"id" => idx, "cloud_name" => k, "active" => v} | acc] 
    end) 
	end

	# projects:
	#   kubernetes: 
	#     active: true
	#     logo_url: "https://raw.githubusercontent.com/cncf/artwork/master/kubernetes/logo.png"
	#     display_name: Kubernetes
	#     sub_title: Orchestration
	#     gitlab_name: Kubernetes
	#     project_url: "https://github.com/kubernetes/kubernetes"
	#   prometheus: 
	#     active: true
	#     logo_url: "https://raw.githubusercontent.com/cncf/artwork/master/prometheus/prometheus_grey_transparent.png"
	#     display_name: Prometheus
	#     sub_title: Monitoring
	#     gitlab_name: prometheus
	#     project_url: "https://github.com/prometheus/prometheus"
	def project_list do
		yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
		yml["projects"] 
		|> Stream.with_index 
		|> Enum.reduce([], fn ({{k, v}, idx}, acc) -> 
			[%{"id" => idx, 
        "yml_name" => k, 
        "active" => v["active"],
        "logo_url" => v["logo_url"],
        "display_name" => v["display_name"],
        "sub_title" => v["sub_title"],
        "gitlab_name" => v["gitlab_name"],
        "project_url" => v["project_url"]} | acc] 
		end) 
	end
end
