require IEx;
defmodule CncfDashboardApi.YmlReader.GitlabCi do
	def get do
		Application.ensure_all_started :inets

    {:ok, resp} = :httpc.request(:get, {'https://gitlab.cncf.ci/cncf/cross-cloud/raw/ci-stable-v0.1.0/.gitlab-ci.yml', []}, [], [body_format: :binary])
		{{_, 200, 'OK'}, _headers, body} = resp
    body
  end
  def cloud_list do
    yml = CncfDashboardApi.YmlReader.GitlabCi.get() |> YamlElixir.read_from_string 
    IEx.pry
    yml["variables"]["ACTIVE_CLOUDS"]
  end
end
