require IEx;
defmodule CncfDashboardApi.YmlReader.GitlabCi do
	def get do
		Application.ensure_all_started :inets

    {:ok, resp} = :httpc.request(:get, {System.get_env("GITLAB_CI_YML") |> to_charlist, []}, [], [body_format: :binary])
		{{_, 200, 'OK'}, _headers, body} = resp
    body
  end
  # def cloud_list do
  #   yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
  #   yml["clouds"] 
  #   |> Stream.with_index 
  #   |> Enum.reduce([], fn ({{k, v}, idx}, acc) -> 
  #     # [%{"id" => (idx + 1), 
  #     [%{"id" => 0, 
  #       "cloud_name" => k, 
  #       "active" => v,
  #       "order" => (idx + 1)} | acc] 
  #   end) 
	# end

  def cloud_list do
    yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
    yml["clouds"] 
    |> Stream.with_index 
    |> Enum.reduce([], fn ({{k, v}, idx}, acc) -> 
      # [%{"id" => (idx + 1), 
      [%{"id" => 0, 
        "cloud_name" => k, 
        "active" => v["active"],
        "display_name" => v["display_name"],
        # "order" => (idx + 1)} | acc] 
        "order" => v["order"]} | acc] 
    end) 
	end

	def project_list do
		yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
		yml["projects"] 
		|> Stream.with_index 
		|> Enum.reduce([], fn ({{k, v}, idx}, acc) -> 
			# [%{"id" => (idx + 1), 
			[%{"id" => 0, 
        "yml_name" => k, 
        "active" => v["active"],
        "logo_url" => v["logo_url"],
        "display_name" => v["display_name"],
        "sub_title" => v["sub_title"],
        "yml_gitlab_name" => v["gitlab_name"],
        "project_url" => v["project_url"],
        "repository_url" => v["repository_url"],
        "timeout" => v["timeout"],
        # "order" => (idx + 1)} | acc] 
        "order" => v["order"]} | acc] 
		end) 
	end

	def gitlab_pipeline_config do
		yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
		yml["gitlab_pipeline"] 
		|> Stream.with_index 
		|> Enum.reduce([], fn ({{k, v}, idx}, acc) -> 
			# [%{"id" => (idx + 1), 
			[%{"id" => 0, 
        "pipeline_name" => k, 
        "timeout" => v["timeout"],
        "status_jobs" => v["status_jobs"],
        } | acc] 
		end) 
	end
end
