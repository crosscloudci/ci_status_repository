require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor.PMToDashboard do 
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo

 @doc """
  Pipeline stages

  Returns `[<stage1>, <stage2>, ...]`
  """
  def pipeline_stages do
    ["build", "provision", "deploy"]
  end

 @doc """
  Project release types

  Returns `[<type1>, <type2>, ...]`
  """
  def project_release_types do
    ["head", "stable"]
  end

  def build_badge_order do
    bo = pipeline_stages() 
    |> Enum.find_index(fn(x) -> 
      x == "build" 
    end)
    bo + 1
  end

  def provision_badge_order do
    packet = Repo.get_by(CncfDashboardApi.Clouds, cloud_name: "packet")
    packet.order + 1
  end

 @doc """
  Kubernetes release types

  Returns `[<type1>, <type2>, ...]`
  """
  def kubernetes_release_types do
    ["head", "stable"]
  end

 @doc """
  Test enviroment types 

  Returns `[<type1>, <type2>, ...]`
  """
  def test_env_types do
    ["amd64", "arm64"]
  end

 @doc """
  Pipeline Types 
  Fill out all possible test environment 'rows'
    -- for #29 this means four hard coded entries:
      --  test environment 'head', project ref 'head'
      --  test environment 'head', project ref 'stable'
      --  test environment 'stable', project ref 'head'
      --  test environment 'stable', project ref 'stable'
  Returns `[<type1>, <type2>, ...]`
  """
  def pipeline_types do
    # TODO build this based on the arrays above or the yml file
    [
      %{:project_release_type => "stable",
      :kubernetes_release_type => "stable",
      :order => 1}, # stable, stable order is always 1
      %{:project_release_type => "stable",
      :kubernetes_release_type => "head",
      :order => 2}, # stable, head order is always 2
      %{:project_release_type => "head",
      :kubernetes_release_type => "head",
      :order => 3}, # head, head order is always 3
      %{:project_release_type => "head",
      :kubernetes_release_type => "stable",
      :order => 4}, # head, stable order is always 4
    ]
  end

 @doc """
  Converts a project monitor into a staged project monitor based on `pipeline_monitor`

  Returns `{:<stage_type>, pipeline_monitor}`
  """
  def pm_to_pm_stage(pm_monitor) do
    pm_stage = {pm_monitor.pipeline_type, pm_monitor}
    pm_stage
  end

 @doc """
  Converts a pm_stage into one or more project rows.

  Make a ref montitor entry for each test environment and update all 
  of them when the *build* status changes for a project. This allows the 
  front end to see a build change regardless of which row is selected
  in the drop down

  Returns `{"build", ref_monitors}` 
  """
  def pm_stage_to_project_rows({"build", pm}) do
    Logger.info fn ->
      "pm_stage_to_project_rows #{inspect({"build", pm})}"
    end
    ref_monitors = []

    build_pipeline = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
                           where: pm1.id == ^pm.internal_build_pipeline_id ) |> List.first

    job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("project")
    
    ref_monitors = pipeline_types() |> Enum.reduce([], fn(pt, acc) ->
      # only set the rows to running for the currently monitored pipeline's release types
      if pm.release_type == pt.project_release_type do
        rm_record = CncfDashboardApi.GitlabMonitor.
        Dashboard.upsert_ref_monitor(pm, # current pipeline monitor 
                                     pm, # target (project) pipeline monitor
                                     build_pipeline, # pipeline for source project
                                     pt.order, # order for the project release/k8/test_env combination
                                     pt.kubernetes_release_type)
        [rm_record | acc]
      else
        acc
      end
    end)
    Logger.info fn ->
      "pm_stage_to_project_rows : #{inspect({"build", pm, ref_monitors})}"
    end
    {"build", pm, ref_monitors} 
  end

 @doc """
  Converts a pm_stage into one or more project rows.

  Returns `{"provision", ref_monitors}`
  """
  def pm_stage_to_project_rows({"provision", pm}) do
    Logger.info fn ->
      "pm_stage_to_project_rows #{inspect({"provision", pm})}"
    end
    ref_monitors = []
    # update the kubenetes project row when the pipeline monitor is a 'provision' pipeline
    build_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.build_pipeline_monitor_by_deploy_pipeline_monitor(pm)
    provision_pipeline = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
                           where: pm1.id == ^pm.provision_pipeline_id ) |> List.first
    Logger.info fn ->
      "provision_pipeline: #{inspect(provision_pipeline)}"
    end
    # job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-cloud")
    
    # loop for all four kubernetes rows (for provisioning there really is only
    # 2 types of clusters, but we have 2 rows (head and stable) for each of the 
    # other projects, so for consistency we update all the rows
    ref_monitors = pipeline_types() |> Enum.reduce([], fn(pt, acc) ->
      Logger.info fn ->
        "pipeline_type: #{inspect(pt)}"
      end
      # only set the rows to running for the currently monitored pipeline's release types
      # The release type of the provision monitor is the kubernetes release type
      if pm.release_type == pt.kubernetes_release_type do
        Logger.info fn ->
          "pm.kubernetes_release_type == pt.kubernetes_release_type"
        end
        rm_record = CncfDashboardApi.GitlabMonitor.
        Dashboard.upsert_ref_monitor(pm, # current pipeline monitor 
                                     build_pm, # target (project) pipeline monitor (kubernetes)
                                     provision_pipeline, # pipeline for provisioner
                                     pt.order, # order for the project release/k8/test_env combination
                                     pt.project_release_type #manually alternate the test_envs (head, stable)
        )
        Logger.info fn ->
          "rm_record: #{inspect(rm_record)}"
        end
        [rm_record | acc]
      else
        acc
      end
    end)
    {"provision", pm, ref_monitors} 
  end

 @doc """
  Converts a pm_stage into one or more project rows.

  Returns `{pm_stage}`
  """
  def pm_stage_to_project_rows({"deploy", pm}) do
    Logger.info fn ->
      "pm_stage_to_project_rows #{inspect({"deploy", pm})}"
    end
    build_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.build_pipeline_monitor_by_deploy_pipeline_monitor(pm)
    provision_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.provision_pipeline_monitor_by_deploy_pipeline_monitor(pm)
    deploy_pipeline = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
                               where: pm1.id == ^pm.pipeline_id ) |> List.first

    pt = pipeline_types() |> Enum.find(fn(x) ->
      x.kubernetes_release_type == provision_pm.release_type and x.project_release_type == provision_pm.release_type
    end)

    rm_record = CncfDashboardApi.GitlabMonitor.Dashboard.upsert_ref_monitor(pm, build_pm, deploy_pipeline, pt.order, pm.kubernetes_release_type)
    {"deploy", pm, [rm_record]} 
  end

 @doc """
  Converts project_rows into project_rows with updated dashboard badge statuses.

  Returns `{:<stage_type>, ref_monitors, dashboard_badge_statuses}`
  """
  def project_rows_to_columns({"build", pm, ref_monitors}) do
    Logger.info fn ->
      "project_rows_to_columns #{inspect({"build", pm, ref_monitors})}"
    end
    dashboard_badge_statuses = []
    build_pipeline = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
                           where: pm1.id == ^pm.internal_build_pipeline_id ) |> List.first
    job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("project")
    Logger.info fn ->
      "project_rows_to_columns build ref_monitors: #{inspect(ref_monitors)}"
    end
    dashboard_badge_statuses = ref_monitors |> Enum.reduce([], fn(rm, acc) ->
    Logger.info fn ->
      "project_rows_to_columns build rm: #{inspect(rm)}"
    end
      badge_url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, pm.pipeline_id)
      Logger.info fn ->
        "badge_url: #{inspect(badge_url)}"
      end
      badge_status = CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, false, "", pm.pipeline_id)
      Logger.info fn ->
        "badge_status: #{inspect(badge_status)}"
      end
      dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm, build_pipeline.ref, badge_status, badge_url, build_badge_order())
      Logger.info fn ->
        "dbs_record: #{inspect(dbs_record)}"
      end

      [dbs_record | acc]
    end)
    {:build, ref_monitors, dashboard_badge_statuses}
  end

 @doc """
  Converts project_rows into project_rows with updated dashboard badge statuses.

  Returns `{:<stage_type>, ref_monitors, dashboard_badge_statuses}`
  """
  def project_rows_to_columns({"provision", pm, ref_monitors}) do
    dashboard_badge_statuses = []
    job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-cloud")
    build_pipeline = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
                           where: pm1.id == ^pm.internal_build_pipeline_id ) |> List.first
    provision_pipeline = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
                           where: pm1.id == ^pm.provision_pipeline_id ) |> List.first
    dashboard_badge_statuses = ref_monitors |> Enum.reduce([], fn(rm, acc) ->
        badge_status = CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, false, "", pm.pipeline_id)
        Logger.info fn ->
          "badge_status: #{inspect(badge_status)}"
        end
        badge_url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, pm.pipeline_id)
        Logger.info fn ->
          "badge_url: #{inspect(badge_url)}"
        end
        dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm, 
                                                                           build_pipeline.ref, 
                                                                           badge_status, 
                                                                           badge_url, 
                                                                           provision_badge_order(),
                                                                           provision_badge_order())
                                                                                  
        Logger.info fn ->
          "dbs_record: #{inspect(dbs_record)}"
        end
        [dbs_record | acc]
    end)
    {:provision, ref_monitors, dashboard_badge_statuses}
  end

 @doc """
  Converts project_rows into project_rows with updated dashboard badge statuses.

  Returns `{:<stage_type>, ref_monitors, dashboard_badge_statuses}`
  """
  def project_rows_to_columns({"deploy", pm, ref_monitors}) do
    dashboard_badge_statuses = []
    packet = Repo.get_by(CncfDashboardApi.Clouds, cloud_name: "packet")
    build_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.build_pipeline_monitor_by_deploy_pipeline_monitor(pm)
    deploy_pipeline = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
                               where: pm1.id == ^pm.pipeline_id ) |> List.first
    job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-project")
    build_jobs = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("project")
    dashboard_badge_statuses = ref_monitors |> Enum.reduce([], fn(rm, acc) ->
      cp_deploy_url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, pm.child_pipeline, pm.pipeline_id) 
      # https://gitlab.vulk.coop/cncf/ci-dashboard/issues/423
      # if build for a project fails, all deploy badges should be N/A 
      if CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(build_jobs, false, "", build_pm.pipeline_id) == "failed" do
        cp_status = "N/A"
      else
        cp_status = CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, pm.child_pipeline, packet.cloud_name, pm.pipeline_id)
      end
      cond do
        (cp_status && cp_status != "") -> 
          status = cp_status 
          deploy_url = cp_deploy_url
        true ->
          status = "N/A"
          deploy_url = "" 
      end
      # ticket #230
      if status == "initial" do
        status = "N/A"
      end
      cloud_order = packet.order + 1
      dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm,
                                                                         deploy_pipeline.ref,
                                                                         status,
                                                                         deploy_url,
                                                                         cloud_order, 
                                                                         packet.id)
      [dbs_record | acc]
    end)
    {:deploy, ref_monitors, dashboard_badge_statuses}
  end

end
