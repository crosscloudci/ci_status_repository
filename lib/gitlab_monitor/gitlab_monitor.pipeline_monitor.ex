require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor.PipelineMonitor do 
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo

 @doc """
  Get the source key models for the source key monitor, the project, and the pipeline 
  based on `source_key_project_monitor_id`.

  Source keys map the keys in gitlab to the keys in our database.

  A migration from gitlab must have occured before calling this function in order to get 
  valid data 

  Returns `{:ok, monitor, source_key_project, source_key_pipeline}`
  """
  def source_models(source_key_project_monitor_id) do
    monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                                        where: skpm.id == ^source_key_project_monitor_id) |> List.first
    source_key_project = Repo.all(from skp in CncfDashboardApi.SourceKeyProjects, 
                                                   where: skp.source_id == ^monitor.source_project_id) |> List.first
    source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.source_pipeline_id) |> List.first
    {:ok, monitor, source_key_project, source_key_pipeline}
  end

 @doc """
  Retrieve the pipeline monitor record based on the `source_key_project_monitor_id`.
  The pipeline monitor record maintains the local keys for monitored pipelines and
  is keyed based on project_id,  pipeline_id and release_type

  Returns `{found, record}`.
  """
  def pipeline_monitor(source_key_project_monitor_id) do
    {:ok, monitor, source_key_project, source_key_pipeline} = source_models(source_key_project_monitor_id)

    # case CncfDashboardApi.GitlabMonitor.Pipeline.is_deploy_pipeline_type(source_key_project.new_id) do
    #   true -> pipeline_type = "deploy"
    #   _ -> pipeline_type = "build"
    # end
    pipeline_type = CncfDashboardApi.GitlabMonitor.Pipeline.pipeline_type(source_key_project.new_id)

    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      pipeline_type: pipeline_type,
      release_type: monitor.pipeline_release_type} 
      |> find_by([:pipeline_id, :project_id, :pipeline_type, :release_type])
  end

 @doc """
  Gets the corresponding build pipeline based on `%PipelineMonitor`.
  Returns `%PipelineMonitor`
  """
  def build_pipeline_monitor_by_deploy_pipeline_monitor(deploy_pipeline_monitor) do
    if (deploy_pipeline_monitor.pipeline_type == "deploy") ||
      (deploy_pipeline_monitor.pipeline_type == "provision") do
      Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                           where: pm.pipeline_id == ^deploy_pipeline_monitor.internal_build_pipeline_id, 
                           where: pm.pipeline_type == "build") 
                           |> List.first()
    else
      # pipeline is a build pipeline
      deploy_pipeline_monitor
    end
  end

 @doc """
  Gets the corresponding provision pipeline based on `%PipelineMonitor`.
  Returns `%PipelineMonitor`
  """
  def provision_pipeline_monitor_by_deploy_pipeline_monitor(deploy_pipeline_monitor) do
    Logger.info fn ->
      "provision_pipeline_monitor_by_deploy_pipeline_monitor: #{inspect(deploy_pipeline_monitor)}"
    end
    case deploy_pipeline_monitor.pipeline_type do
      "deploy" ->
        Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                             where: pm.pipeline_id == ^deploy_pipeline_monitor.provision_pipeline_id, 
                             where: pm.pipeline_type == "provision") 
                             |> List.first()
      "provision" ->
        # pipeline is a provision pipeline
        deploy_pipeline_monitor
      "build" ->
        Logger.info fn ->
          "Can't get a provision pipeline from a build pipeline deploy_pipeline_monitor: #{inspect(deploy_pipeline_monitor)}"
        end
      _ ->
        Logger.info fn ->
           "No provision pipeline type for deploy_pipeline_monitor: #{inspect(deploy_pipeline_monitor)}"
        end
        raise "No provision pipeline type for deploy_pipeline_monitor: #{inspect(deploy_pipeline_monitor)}"
    end
  end

end
