require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor do
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo

 @doc """
  Updates the dashboard based on `source_key_project_monitor_id`.

  Returns `:ok`
  """
  def update_dashboard(source_key_project_monitor_id) do
    CncfDashboardApi.GitlabMonitor.Dashboard.last_checked()
    migrate_source_key_monitor(source_key_project_monitor_id)
    |> upsert_pipeline_monitor_info
    |> upsert_gitlab_to_ref_monitor 
    CncfDashboardApi.GitlabMonitor.Dashboard.broadcast()
    :ok
  end 

 @doc """
  Checks if the target project has been migrated based on `project_name` and `source_pipeline_id`.

  Returns `boolean`.
  """
  def target_project_exist?(project_name, source_pipeline_id) do
    {p_found, p_record} = %CncfDashboardApi.Projects{name: project_name } |> find_by([:name])
    {pl_found, pl_record} = %CncfDashboardApi.SourceKeyPipelines{source_id: source_pipeline_id } |> find_by([:source_id])
    Logger.info fn ->
      "GitlabMonitor: target_project_exist? project, source_key_pipeline : #{inspect(p_record)}, #{inspect(pl_record)}"
    end
    if (p_found == :not_found || pl_found == :not_found) do
      false
    else
      true
    end
  end

  def migrate_source_key_monitor(source_key_project_monitor_id) do
    # migrate clouds
    CncfDashboardApi.GitlabMigrations.upsert_clouds()
    # need to upsert all the projects to keep the dashboard listing all current projects
    CncfDashboardApi.GitlabMigrations.upsert_projects()
    monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                       where: skpm.id == ^source_key_project_monitor_id) |> List.first
    Logger.info fn ->
      "migrate_source_key_monitor: source_key_project_monitor : #{inspect(monitor)}"
    end

    # make sure the immediate project is upserted
    {:ok, upsert_count, project_map} = CncfDashboardApi.GitlabMigrations.upsert_project(monitor.source_project_id) 

    # upsert yml project properties
    CncfDashboardApi.GitlabMigrations.upsert_yml_projects()

    # get the local project id
    source_key_project = Repo.all(from skp in CncfDashboardApi.SourceKeyProjects, 
                                  where: skp.source_id == ^monitor.source_project_id) |> List.first

                                  # migrate pipeline 
    {:ok, upsert_count, pipeline_map} = CncfDashboardApi.GitlabMigrations.upsert_pipeline(monitor.source_project_id, monitor.source_pipeline_id) 

    # get the local pipeline
    source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                   where: skp.source_id == ^monitor.source_pipeline_id) 
                                   |> List.first
    # get the local provision pipeline
    source_key_provision_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                   where: skp.source_id == ^monitor.provision_pipeline_id) 
                                   |> List.first

    # migrate missing internal id, if it doesn't exist
    unless target_project_exist?(monitor.target_project_name, monitor.project_build_pipeline_id) do
      Logger.info fn ->
        "migrate_source_key_monitor: target_project did not exist"
      end
      CncfDashboardApi.GitlabMigrations.upsert_missing_target_project_pipeline( monitor.target_project_name, monitor.project_build_pipeline_id)
    end

    target_source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.project_build_pipeline_id) |> List.first

    Logger.info fn ->
      "migrate_source_key_monitor: monitor : #{inspect(monitor)}"
    end

    Logger.info fn ->
      "migrate_source_key_monitor: source_key_project : #{inspect(source_key_project)}"
    end

    Logger.info fn ->
      "migrate_source_key_monitor: target_source_key_pipeline : #{inspect(target_source_key_pipeline)}"
    end
                                   
    Logger.info fn ->
      "migrate_source_key_monitor: source_key_provision_pipeline : #{inspect(source_key_provision_pipeline)}"
    end
    {:ok, {monitor, source_key_project, source_key_pipeline, source_key_project_monitor_id, target_source_key_pipeline, source_key_provision_pipeline}}
  end

 @doc """
  Migrates the source key pipeline_monitor into the internal pipeline monitor based on `{%monitor, %source_key_project, %source_key_pipeline, source_key_project_monitor_id}`.

  Returns `[%SourceKeyProjects, %SourceKeyPipelines]`
  """
  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    update_dashboard(source_key_project_monitor_id)
  end

  def upsert_pipeline_monitor_info({:ok, source_key_project_info}) do
    upsert_pipeline_monitor_info(source_key_project_info)
  end

 @doc """
  Migrates the source key pipeline_monitor into the internal pipeline monitor based on `source_key_project_monitor_id`.

  Returns `[%SourceKeyProjects, %SourceKeyPipelines]`
  """
  def upsert_pipeline_monitor_info({monitor, source_key_project, source_key_pipeline, source_key_project_monitor_id, target_source_key_pipeline, source_key_provision_pipeline} = source_key_project_info) do

    CncfDashboardApi.GitlabMonitor.Dashboard.last_checked()

    pipeline_type =  CncfDashboardApi.GitlabMonitor.Pipeline.pipeline_type(source_key_project.new_id) 

    alternate_release = if (monitor.pipeline_release_type == "stable"), do: "head", else: "stable"

    #TODO we now can monitor, for the same pipeline, multiple release types that are the same (two for stable but that have different *kubernetes* release types or archs)
    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      release_type: alternate_release} 
      |> find_by([:pipeline_id, :project_id, :release_type])

      case pm_found do
        :found -> 
          # raise "You may not monitor the same project and pipeline for two different branches"
          Logger.info fn ->
            "upsert_pipeline_monitor_info Monitoring the same project and pipeline for two different branches #{inspect(source_key_project)}"
          end
        _ -> :ok
      end

      case pipeline_type do
        "deploy" -> 
          Logger.info fn ->
            "upsert_pipeline_monitor_info source_key_provision_pipeline: #{inspect(source_key_provision_pipeline)}"
          end

          # provision_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.provision_pipeline_monitor_by_deploy_pipeline_monitor(pm_record)
          provision_pipeline_id = source_key_provision_pipeline.new_id
          kubernetes_release_type = monitor.kubernetes_release_type
          Logger.info fn ->
            "upsert_pipeline_monitor_info provision_pipeline_id, kubernetes_release_type #{inspect(provision_pipeline_id)} #{inspect(kubernetes_release_type)} "
          end
        "provision" -> 
          provision_pipeline_id = source_key_pipeline.new_id 
          kubernetes_release_type = monitor.kubernetes_release_type 
        "build" ->
          provision_pipeline_id = 0 
          kubernetes_release_type = monitor.kubernetes_release_type 
        _ ->
          Logger.error fn ->
            "legacy pipeline (no pipeline_type): #{inspect(monitor)}"
          end
      end
      # Insert only if pipeline, project, and release type and kubernetes release type do not exist
      # else update
      {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
        project_id: source_key_project.new_id,
        pipeline_type: pipeline_type,
        release_type: monitor.pipeline_release_type,
        kubernetes_release_type: monitor.kubernetes_release_type } 
        |> find_by([:pipeline_id, :project_id, :pipeline_type, :release_type, :kubernetes_release_type])

      Logger.info fn ->
        "pm_record #{inspect(pm_record)}"
      end

      changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, 
                                                               %{project_id: source_key_project.new_id,
                                                                 pipeline_id: source_key_pipeline.new_id,
                                                                 running: true,
                                                                 release_type: monitor.pipeline_release_type,
                                                                 pipeline_type: pipeline_type,
                                                                 cloud: monitor.cloud,
                                                                 child_pipeline: monitor.child_pipeline,
                                                                 target_project_name: monitor.target_project_name,
                                                                 kubernetes_release_type: kubernetes_release_type,
                                                                 test_env: kubernetes_release_type,
                                                                 provision_pipeline_id: provision_pipeline_id,
                                                                 arch: monitor.arch,
                                                                 internal_build_pipeline_id: target_source_key_pipeline.new_id
                                                               })

    case pm_found do
      :found ->
        {_, pm_record} = Repo.update(changeset) 
        Logger.info fn ->
          "found: update pipeline monitor: #{inspect(pm_record)}"
        end
      :not_found ->
        {_, pm_record} = Repo.insert(changeset) 
        Logger.info fn ->
          "not found: insert pipeline monitor: #{inspect(pm_record)}"
        end
    end

    # migrate all jobs for the pipeline 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(monitor.source_project_id |> String.to_integer, 
                                                           monitor.source_pipeline_id |> String.to_integer)

    project_pipeline_info = CncfDashboardApi.GitlabMonitor.Pipeline.project_pipeline_info(source_key_project.new_id, source_key_pipeline.new_id)
  end

 @doc """
  Updates one ref monitor based on `project_id` and  `pipeline_id`.

  project, pipeline, and pipeline jobs should be migrated before
    calling upsert_gitlab_to_ref_monitor 

  1. source_key_project_monitor is called from a http post
  2. pipeline_monitor is created/updated during the http_post
  3. upsert_gitlab_to_ref_monitor is called to set up the dashboard

  Returns `[%DashboardBadgeStatus]`
  """
  def upsert_gitlab_to_ref_monitor(project_id, pipeline_id) do
    Logger.info fn ->
      "upsert_ref_monitor project id: #{project_id} pipeline_id: #{pipeline_id}"
    end
    project_pipeline_info = CncfDashboardApi.GitlabMonitor.Pipeline.project_pipeline_info(project_id, pipeline_id)
    upsert_gitlab_to_ref_monitor(project_pipeline_info)
  end

  def upsert_gitlab_to_ref_monitor({:ok, project, pipeline, pipeline_jobs, pipeline_monitor} = project_pipeline_monitor) do
    upsert_gitlab_to_ref_monitor({project, pipeline, pipeline_jobs, pipeline_monitor})
  end

 @doc """
  Updates one ref monitor based on `{%Project, %Pipeline, [%PipelineJobs], %PipelineMonitor}`.

  project, pipeline, and pipeline jobs should be migrated before
    calling upsert_gitlab_to_ref_monitor 

  1. source_key_project_monitor is called from a http post
  2. pipeline_monitor is created/updated during the http_post
  3. upsert_gitlab_to_ref_monitor is called to set up the dashboard

  Returns `[%DashboardBadgeStatus]`
  """
  def upsert_gitlab_to_ref_monitor({project, pipeline, pipeline_jobs, pipeline_monitor} = project_pipeline_monitor) do

    Logger.info fn ->
      "upsert_ref_monitor/1 project id: #{project.id} pipeline_id: #{pipeline.id}"
    end
    
    project_id = project.id
    pipeline_id = pipeline.id

    # initialize the dashboard on build pipeline only
    if pipeline_monitor.pipeline_type == "build" do
      CncfDashboardApi.GitlabMonitor.Dashboard.initialize_ref_monitor(project_id)
    end

    #  get all clouds
    clouds = Repo.all(from c in CncfDashboardApi.Clouds)

    # TODO if never given a release status for the pipeline, raise an error

    # if  deploy pipline, use the target project for the refmonitor
    Logger.info fn ->
      " upsert_ref_monitor pipeline_monitor.internal_build_pipeline_id: #{inspect(pipeline_monitor.internal_build_pipeline_id)}"
    end
    Logger.info fn ->
      " upsert_ref_monitor all build pipeline_monitors: #{inspect(Repo.all(CncfDashboardApi.PipelineMonitor) )}"
    end

    {target_pm, target_pl} = CncfDashboardApi.GitlabMonitor.Pipeline.target_pipeline_info(pipeline_monitor, pipeline)
    
    # https://github.com/vulk/cncf_ci/issues/29
    # Only deploy pipelines will have a test_env.  
    # Add test environment field to the database
    #       --  test environment 'stable', project ref 'stable' = 1
    #       --  test environment 'stable', project ref 'head' = 2
    #       --  test environment 'head', project ref 'head' = 3
    #       --  test environment 'head', project ref 'stable' = 4
    case  pipeline_monitor.pipeline_type do
      "build" -> 
        # no build jobs have test enviroments, but we must make a ref montitor entry for each test environment
        # and update all of them when the build status changes for a project in order
        # for the drop down to see a build change
        job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("project")
        if pipeline_monitor.release_type == "stable" do
          rm_record = CncfDashboardApi.GitlabMonitor.Dashboard.upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, 1, "stable")
          dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm_record,
                                                                             target_pl.ref,
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, false, "", target_pm.pipeline_id),
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, target_pm.pipeline_id),
                                                                             1)
          rm_record = CncfDashboardApi.GitlabMonitor.Dashboard.upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, 4, "head")
          dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm_record,
                                                                             target_pl.ref,
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, false, "", target_pm.pipeline_id),
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, target_pm.pipeline_id),
                                                                             1)
        else
          rm_record = CncfDashboardApi.GitlabMonitor.Dashboard.upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, 2, "stable")
          dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm_record,
                                                                             target_pl.ref,
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, false, "", target_pm.pipeline_id),
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, target_pm.pipeline_id),
                                                                             1)
          rm_record = CncfDashboardApi.GitlabMonitor.Dashboard.upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, 3, "head")
          dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm_record,
                                                                             target_pl.ref,
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, false, "", target_pm.pipeline_id),
                                                                             CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, false, target_pm.pipeline_id),
                                                                             1)
        end
      "deploy" ->
        Logger.info fn ->
          "deploy pipeline monitor upsert_gitlab_to_ref_monitor"
        end
        cond do
          pipeline_monitor.kubernetes_release_type == "stable" and target_pm.release_type == "stable" -> 
            pipeline_order = 1
          pipeline_monitor.kubernetes_release_type == "stable" and target_pm.release_type == "head" -> 
            pipeline_order = 2
          pipeline_monitor.kubernetes_release_type == "head" and target_pm.release_type == "head" -> 
            pipeline_order = 3
          pipeline_monitor.kubernetes_release_type == "head" and target_pm.release_type == "stable" -> 
            pipeline_order = 4
        end
        rm_record = CncfDashboardApi.GitlabMonitor.Dashboard.upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, pipeline_order, 
                                                                                pipeline_monitor.kubernetes_release_type)
      "provision" ->
        Logger.info fn ->
          "No ref_monitor_upsert for provision pipeline monitors: #{inspect(pipeline_monitor)}"
        end
      _ ->
        Logger.error fn ->
          "Legacy dependency.  A pipeline_monitor with no pipeline_type exists: #{inspect(pipeline_monitor)}"
        end
        raise "There should be no pipeline_monitors with no pipeline_type that is not a build, provision, or deploy type"
    end




    # if pipeline_type = "build" then the project_id is a target project
    # if pipeline_type = "deploy" then this is a pipeline project 
    # deploy pipeline monitors correspond to the cloud badges on the dashboard
    case pipeline_monitor.pipeline_type do
      "build" ->
      deploy_pipeline_monitors = Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                                          where: pm.internal_build_pipeline_id == ^pipeline_monitor.pipeline_id,
                                          where: pm.pipeline_type == "deploy") 
      n when n in ["deploy", "provision"]   ->
      deploy_pipeline_monitors = Repo.all(from pm in CncfDashboardApi.PipelineMonitor, 
                                          where: pm.internal_build_pipeline_id == ^pipeline_monitor.internal_build_pipeline_id,
                                          where: pm.pipeline_type == "deploy")
      _ -> 
      Logger.info fn ->
        "No deploy pipeline monitors for a provision pipeline: #{inspect(pipeline_monitor)}"
      end

    end

    sorted_deploy_pipeline_monitors = deploy_pipeline_monitors 
                                      |> Enum.sort_by(fn(x)-> NaiveDateTime.to_erl(x.updated_at) end)
    Logger.info fn ->
      "sorted deploy_pipeline_monitors : #{inspect(sorted_deploy_pipeline_monitors)}"
    end

    sorted_source_key_pipelines = deploy_pipeline_monitors 
                                  |> Enum.map(fn(x) ->
                                    Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelines, 
                                             where: skpj.new_id == ^x.pipeline_id)
                                  end)
                                  |> List.flatten
                                  |> Enum.sort_by(fn(x)-> NaiveDateTime.to_erl(x.updated_at) end)

    Logger.info fn ->
      "Sorted deploy source key pipelines : #{inspect(sorted_source_key_pipelines)}"
    end

    sorted_source_key_project_monitors = sorted_source_key_pipelines 
                                          |> Enum.map(fn(x) ->
                                            Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                                                     where: skpm.source_pipeline_id == ^x.source_id)
                                          end)
                                          |> List.flatten
                                          |> Enum.sort_by(fn(x)-> NaiveDateTime.to_erl(x.updated_at) end)
    Logger.info fn ->
      "Sorted deploy source key project monitors : #{inspect(sorted_source_key_project_monitors)}"
    end

    cc = Repo.all(from p in CncfDashboardApi.Projects, where: p.name == "cross-cloud") |> List.last
    Logger.info fn ->
      "cross_cloud project: #{inspect(cc)}"
    end

    cp = Repo.all(from p in CncfDashboardApi.Projects, where: p.name == "cross-project") |> List.first
    Logger.info fn ->
      "cross_project project: #{inspect(cp)}"
    end

    #loop through all clouds
    posted_clouds = deploy_pipeline_monitors |> Enum.uniq_by(fn(x) -> x.cloud end) |> Enum.reduce([], fn(x,acc)-> [x.cloud | acc] end)
    Logger.info fn ->
      "posted_clouds : #{inspect(posted_clouds)}"
    end

    cloud_list = Repo.all(from cd1 in CncfDashboardApi.Clouds, where: cd1.active == true, where: cd1.cloud_name in ^posted_clouds, order_by: [cd1.order]) 
    Logger.info fn ->
      "filtered cloud_list : #{inspect(cloud_list)}"
    end

    #only loop through clouds that have deploy pipeline monitors
    Enum.map(cloud_list, fn(cloud) ->
      Logger.info fn ->
        "cloud_name: #{inspect(cloud.cloud_name)}"
      end
      
      # Use latest deploy_pipeline_monitor for the current cloud
      cross_cloud_pipeline_monitor = Enum.filter(deploy_pipeline_monitors, fn(x) ->
        x.project_id == cc.id && x.cloud == cloud.cloud_name
      end)
      |> Enum.sort_by(fn(x)-> NaiveDateTime.to_erl(x.updated_at) end) 
      |> List.last

      cross_project_pipeline_monitor = Enum.filter(deploy_pipeline_monitors, fn(x) ->
        x.project_id == cp.id && x.cloud == cloud.cloud_name
      end)
      |> Enum.sort_by(fn(x)-> NaiveDateTime.to_erl(x.updated_at) end) 
      |> List.last

      Logger.info fn ->
        "cross_cloud_pipeline_monitor: #{inspect(cross_cloud_pipeline_monitor)}"
      end

      if cross_cloud_pipeline_monitor do
        job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-cloud")
        # https://gitlab.vulk.coop/cncf/ci-dashboard/issues/423
        # if build for a project fails, all deploy badges should be N/A
        if CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(
          CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("project"), 
          false, 
          "", 
          target_pm.pipeline_id) == "failed" do
          cc_status = "N/A"
        else
          cc_status = CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, cross_cloud_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_cloud_pipeline_monitor.pipeline_id)
        end
        
        cc_deploy_url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, cross_cloud_pipeline_monitor.child_pipeline, cross_cloud_pipeline_monitor.pipeline_id)
      end

      Logger.info fn ->
        "cross_project_pipeline_monitor: #{inspect(cross_project_pipeline_monitor)}"
      end

      if cross_project_pipeline_monitor do
        job_names = CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("cross-project")
        # https://gitlab.vulk.coop/cncf/ci-dashboard/issues/423
        # if build for a project fails, all deploy badges should be N/A
        if CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(
          CncfDashboardApi.GitlabMonitor.Job.monitored_job_list("project"), 
          false, 
          "", 
          target_pm.pipeline_id) == "failed" do
          cp_status = "N/A"
        else
          cp_status = CncfDashboardApi.GitlabMonitor.Job.badge_status_by_pipeline_id(job_names, cross_project_pipeline_monitor.child_pipeline, cloud.cloud_name, cross_project_pipeline_monitor.pipeline_id)
        end
        cp_deploy_url = CncfDashboardApi.GitlabMonitor.Job.badge_url(job_names, cross_project_pipeline_monitor.child_pipeline, cross_project_pipeline_monitor.pipeline_id)
      end

      cond do
        (cp_status && cp_status != "" && cc_status != "failed") -> 
          status = cp_status 
          deploy_url = cp_deploy_url
        (cc_status && cc_status != "") ->
          status = cc_status 
          deploy_url = cc_deploy_url
        true ->
          status = "N/A"
          deploy_url = "" 
      end

      Logger.info fn ->
        "cp_status: #{inspect(cp_status)}"
      end
      Logger.info fn ->
        "cc_status: #{inspect(cc_status)}"
      end
      Logger.info fn ->
        "status: #{inspect(status)}"
      end
      Logger.info fn ->
        "deploy_url: #{inspect(deploy_url)}"
      end
      Logger.info fn ->
        "all dashboards status: #{inspect(Repo.all(
          from dbs in CncfDashboardApi.DashboardBadgeStatus,
          where: dbs.ref_monitor_id == ^rm_record.id))}"
      end

      cloud_order = cloud.order + 1
      Logger.info fn ->
        "cloud : #{inspect(cloud)}"
      end

      # ticket #230
      if status == "initial" do
        status = "N/A"
        Logger.error fn ->
          "invalid status for pipline: #{inspect(cc_status)}, #{inspect(cp_status)}"
        end
      else

    dbs_record = CncfDashboardApi.GitlabMonitor.Dashboard.update_badge(rm_record,
                                                                       target_pl.ref,
                                                                       status,
                                                                       deploy_url,
                                                                       cloud_order, 
                                                                       cloud.id
    )

      end
    end)
  end

  def cloud_order_by_name(cloud_name) do
    Logger.info fn ->
      "cloud_order_by_name: #{inspect(cloud_name)}"
    end
    {p_found, c_record} = %CncfDashboardApi.Clouds{cloud_name: cloud_name } |> find_by([:cloud_name])
    order = if p_found do
      c_record.order + 1 # clouds start with 2 wrt badge status
    else
      :error
    end
  end

end
