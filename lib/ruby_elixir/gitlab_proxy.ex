defmodule RubyElixir.GitLabProxy do
  use Export.Ruby

  def get_gitlab_user do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/ruby"))
    ruby
    |> Ruby.call("gitlab_proxy", "puts_user", [])
  end

  def get_gitlab_project_names do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/ruby"))
    {:ok, projects} = ruby |> Ruby.call("gitlab_proxy", "get_project_names", [])
    ruby |> Ruby.stop()
    Poison.decode!(projects) 
  end

  def get_gitlab_projects do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/ruby"))
    {:ok, projects} = ruby |> Ruby.call("gitlab_proxy", "get_projects", [])
    ruby |> Ruby.stop()
    Poison.decode!(projects) 
  end

  def get_gitlab_pipelines(project_id) do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/ruby"))
    # need to page through all calls
    {:ok, pipelines} = ruby |> Ruby.call("gitlab_proxy", "get_pipelines", [project_id])
    ruby |> Ruby.stop()
    Poison.decode!(pipelines) 
  end
end 
