require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor.Pipeline do 
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo

 @doc """
  Determines if a project/code associated with a pipeline implements a deploy pipeline
  or a build pipeline a based on `project_id`.

  Based on if project name is either cross-cloud/cross-project 
  (cross-cloud/cross-project handles the deploy pipelines) or not (i.e. a build pipeline)

  Returns `boolean`
  """
  def is_deploy_pipeline_type(project_id) do
    project = Repo.all(from skp in CncfDashboardApi.Projects, 
                       where: skp.id == ^project_id) |> List.first
    Logger.info fn ->
      "is_deploy_pipeline_type project: #{inspect(project)}"
    end
    if (project.name =~ "cross-cloud" || project.name =~ "cross-project") do
      true
    else
      false
    end

  end

 @doc """
  Determines pipeline type based on `project_id`.

  Returns `string`
  """
  def pipeline_type(project_id) do
    project = Repo.all(from skp in CncfDashboardApi.Projects, 
                       where: skp.id == ^project_id) |> List.first
    Logger.info fn ->
      "pipeline_type project: #{inspect(project)}"
    end
    case project.name do
      "cross-cloud" -> 
        "provision"
      "cross-project" ->
        "deploy"
      _ -> 
        "build"
    end
  end

 @doc """
  Selects the target pipeline info based on `{%PipelineMonitor, %Pipeline}`.

  target pipeline is the current (passed in) pipeline and pipeline monitor
  if the pipeline type is `deploy`

  target pipeline is based on the internal_build_pipeline_id 
  if the pipeline type is `build`

  Returns `{%PipelineMonitor, %Pipelines}`
  """
 def target_pipeline_info(pipeline_monitor, pipeline) do
  target_pm = nil
  target_pl = nil
   if (pipeline_monitor.pipeline_type == "deploy") || (pipeline_monitor.pipeline_type == "provision") do
      target_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.build_pipeline_monitor_by_deploy_pipeline_monitor(pipeline_monitor)
      target_pl = Repo.all(from pm in CncfDashboardApi.Pipelines, where: pm.id == ^pipeline_monitor.internal_build_pipeline_id ) |> List.first

      if is_nil(target_pm) do
        Logger.error fn ->
          "Legacy dependency.  A deploy call with no build calls has been found for: #{inspect(pipeline_monitor)}"
        end
        raise "There should be no deploy pipelines that do not have a corresponding build pipeline 
        Must be a legacy call.  This deploy pipeline call is probably for a dependency that no 
        longer exists in the db"
        # target_pm = pipeline_monitor
        # target_pl = pipeline
      end
      Logger.info fn ->
        " target_pipeline_info deploy target_pm: #{inspect(target_pm)}"
      end
    else
      Logger.info fn ->
        " target_pipeline_info build target_pm: #{inspect(pipeline_monitor)}"
      end
      target_pm = pipeline_monitor
      target_pl = pipeline
    end
    {target_pm, target_pl}
 end

 @doc """
  Selects the target pipeline info based on `{%PipelineMonitor, %Pipeline}`.

  target pipeline is the current (passed in) pipeline and pipeline monitor
  if the pipeline type is `deploy`

  target pipeline is based on the internal_build_pipeline_id 
  if the pipeline type is `build`

  Returns `{%PipelineMonitor, %Pipelines}`
  """
 def provision_pipeline_info(pipeline_monitor, pipeline) do
  provision_pm = nil
  provision_pl = nil
   case pipeline_monitor.pipeline_type do
     "deploy" ->
      provision_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.provision_pipeline_monitor_by_deploy_pipeline_monitor(pipeline_monitor)
      provision_pl = Repo.all(from pm in CncfDashboardApi.Pipelines, 
                           where: pm.id == ^pipeline_monitor.provision_pipeline_id ) |> List.first

      if is_nil(provision_pm) do
        Logger.error fn ->
          "Legacy dependency.  A deploy call with no provision calls has been found for: #{inspect(pipeline_monitor)}"
        end
        raise "There should be no deploy pipelines that do not have a corresponding provision pipeline 
        Must be a legacy call.  This deploy pipeline call is probably for a dependency that no 
        longer exists in the db"
      end
      Logger.info fn ->
        " provision_pipeline_info deploy -> provision_pm: #{inspect(provision_pm)}"
      end
    "provision" -> 
      Logger.info fn ->
        " provision_pipeline_info provision -> provision pm: #{inspect(pipeline_monitor)}"
      end
      provision_pm = pipeline_monitor
      provision_pl = pipeline
     _ ->
      Logger.error fn ->
        " provision_pipeline_info A build pipeline monitor will not ever refer to a provision pm: #{inspect(pipeline_monitor)}"
      end
    end
    {provision_pm, provision_pl}
 end

 @doc """
 Gets all project and pipeline information based on the internal
 `project_id` and  `pipeline_id`.

  project, pipeline, and pipeline jobs should be migrated before
    calling project_pipeline_info 

  Returns `{:ok, %Projects, %Pipelines, [%PipelineJobs], %PipelineMonitor]}`
  """
  def project_pipeline_info(project_id, pipeline_id) do
    Logger.info fn ->
      "project_pipeline_info project id: #{project_id} pipeline_id: #{pipeline_id}"
    end
    project = Repo.all(from p in CncfDashboardApi.Projects, 
                       where: p.id == ^project_id) |> List.first
                       # get pipeline
    pipeline = Repo.all(from p in CncfDashboardApi.Pipelines, 
                        where: p.id == ^pipeline_id) |> List.first
                        # get pipeline jobs
    pipeline_jobs = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                             where: pj.pipeline_id == ^pipeline_id)

    {pm_found, pipeline_monitor} = %CncfDashboardApi.PipelineMonitor{pipeline_id: pipeline.id, 
      project_id: project_id} |> find_by([:pipeline_id, :project_id])

    Logger.info fn ->
      "project_pipeline_info pipeline_monitor: #{inspect(pipeline_monitor)}"
    end

    {:ok, project, pipeline, pipeline_jobs, pipeline_monitor}
  end


end
