defmodule CncfDashboardApi.YmlReader.GitlabCi do
	def get do
		Application.ensure_all_started :inets

    {:ok, resp} = :httpc.request(:get, {System.get_env("GITLAB_CI_YML") |> to_charlist, []}, [], [body_format: :binary])
		{{_, 200, 'OK'}, _headers, body} = resp
    body
  end
  def cloud_list do
    yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
    yml["variables"]["ACTIVE_CLOUDS"] 
    |> String.split(",")
    |> Stream.with_index 
    |> Enum.reduce([], 
                   fn ({x,idx},acc) -> 
                     [%{"id" => idx, "cloud_name" => x} | acc] 
                   end)
  end
end
