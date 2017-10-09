defmodule GitLabProxy do
  use Export.Ruby

  def get_gitlab_user do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    ruby
    |> Ruby.call("gitlab_proxy", "puts_user", [])
  end

  def get_gitlab_project_names do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, projects} = ruby |> Ruby.call("gitlab_proxy", "get_project_names", [])
    ruby |> Ruby.stop()
    Poison.decode!(projects) 
  end

  def get_gitlab_projects do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, projects} = ruby |> Ruby.call("gitlab_proxy", "get_projects", [])
    ruby |> Ruby.stop()
    Poison.decode!(projects) 
  end

  def get_gitlab_pipelines(project_id) do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, pipelines} = ruby |> Ruby.call("gitlab_proxy", "get_pipelines", [project_id])
    ruby |> Ruby.stop()
    Poison.decode!(pipelines) 
  end

  def get_gitlab_pipeline_jobs(project_id, pipeline_id) do
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, jobs} = ruby |> Ruby.call("gitlab_proxy", "get_pipeline_jobs", [project_id, pipeline_id])
    ruby |> Ruby.stop()
    Poison.decode!(jobs) 
  end
end 
