require Logger;
defmodule GitLabProxy do
  use Export.Ruby
  use Retry

  def get_gitlab_user do
    retry with: exp_backoff |> randomize |> cap(1_000) |> expiry(10_000), rescue_only: [MatchError] do  
    Logger.info fn ->
      "Trying get_gitlab_user"
    end
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    ruby
    |> Ruby.call("gitlab_proxy", "puts_user", [])
    end
  end

  @doc """
  Returns a list of projects 

  ## Examples

      iex> gpn = GitLabProxy.get_gitlab_project_names
      iex> Enum.find_value(gpn, fn(x) -> x == "cross-project" end)
      true

  """
  def get_gitlab_project_names do
    retry with: exp_backoff |> randomize |> cap(1_000) |> expiry(10_000), rescue_only: [MatchError] do  
    Logger.info fn ->
      "Trying get_gitlab_project_names"
    end
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, projects} = ruby |> Ruby.call("gitlab_proxy", "get_project_names", [])
    ruby |> Ruby.stop()
    Poison.decode!(projects) 
    end
  end

  @doc """
  Returns all projects 

  """
  def get_gitlab_projects do
    retry with: exp_backoff |> randomize |> cap(1_000) |> expiry(10_000), rescue_only: [MatchError] do  
    Logger.info fn ->
      "Trying get_gitlab_projects"
    end
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, projects} = ruby |> Ruby.call("gitlab_proxy", "get_projects", [])
    ruby |> Ruby.stop()
    Poison.decode!(projects) 
    end
  end

  @doc """
  Returns one project 

  """
  def get_gitlab_project(source_project_id) do
    retry with: exp_backoff |> randomize |> cap(1_000) |> expiry(10_000), rescue_only: [MatchError] do  
    Logger.info fn ->
      "Trying get_gitlab_project"
    end
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, projects} = ruby |> Ruby.call("gitlab_proxy", "get_project", [source_project_id])
    ruby |> Ruby.stop()
    Poison.decode!(projects) 
    end
  end

  @doc """
  Returns a list of pipelines 

  ## Parameters

    - name: Integer that represents a project id.

  ## Examples

      iex> %{"id" => a} = GitLabProxy.get_gitlab_pipelines("1") |> List.first   
      iex> a |> is_number
      true

  """
  def get_gitlab_pipelines(project_id) do
    retry with: exp_backoff |> randomize |> cap(1_000) |> expiry(10_000), rescue_only: [MatchError] do  
    Logger.info fn ->
      "Trying get_gitlab_pipelines for project id: #{inspect(project_id)}"
    end
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, pipelines} = ruby |> Ruby.call("gitlab_proxy", "get_pipelines", [project_id])
    ruby |> Ruby.stop()
    Poison.decode!(pipelines) 
    end
  end

  def get_gitlab_pipeline(project_id, pipeline_id) do
    retry with: exp_backoff |> randomize |> cap(1_000) |> expiry(10_000), rescue_only: [MatchError] do  
    Logger.info fn ->
      "Trying get_gitlab_pipeline for project_id: #{inspect(project_id)} pipeline_id #{inspect(pipeline_id)}"
    end
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, pipelines} = ruby |> Ruby.call("gitlab_proxy", "get_pipeline", [project_id, pipeline_id])
    ruby |> Ruby.stop()
    Poison.decode!(pipelines) 
    end
  end

  def get_gitlab_pipeline_jobs(project_id, pipeline_id) do
    retry with: exp_backoff |> randomize |> cap(1_000) |> expiry(10_000), rescue_only: [MatchError] do  
    Logger.info fn ->
      "Trying get_gitlab_pipeline_jobs"
    end
    {:ok, ruby} = Ruby.start(ruby_lib: Path.expand("lib/gitlab"))
    {:ok, jobs} = ruby |> Ruby.call("gitlab_proxy", "get_pipeline_jobs", [project_id, pipeline_id])
    ruby |> Ruby.stop()
    Poison.decode!(jobs) 
    end
  end
end 
