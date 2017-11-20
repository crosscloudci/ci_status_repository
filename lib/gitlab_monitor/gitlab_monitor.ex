require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor do
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: CncfDashboardApi.Repo


  def last_checked do
    yml = System.get_env("GITLAB_CI_YML")
    {d_found, d_record} = %CncfDashboardApi.Dashboard{gitlab_ci_yml: yml } |> find_by([:gitlab_ci_yml])
    changeset = CncfDashboardApi.Dashboard.changeset(d_record, %{last_check: Ecto.DateTime.utc, gitlab_ci_yml: yml, })
    case d_found do
      :found ->
        {_, d_record} = Repo.update!(changeset) 
      :not_found ->
        {_, d_record} = Repo.insert!(changeset) 
    end
  end

  def source_models(source_key_project_monitor_id) do
    monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                                        where: skpm.id == ^source_key_project_monitor_id) |> List.first
    source_key_project = Repo.all(from skp in CncfDashboardApi.SourceKeyProjects, 
                                                   where: skp.source_id == ^monitor.source_project_id) |> List.first
    source_key_pipeline = Repo.all(from skp in CncfDashboardApi.SourceKeyPipelines, 
                                                   where: skp.source_id == ^monitor.source_pipeline_id) |> List.first
    {:ok, monitor, source_key_project, source_key_pipeline}
  end

  def pipeline_monitor(source_key_project_monitor_id) do
    {:ok, monitor, source_key_project, source_key_pipeline} = source_models(source_key_project_monitor_id)

    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      release_type: monitor.pipeline_release_type} 
      |> find_by([:pipeline_id, :project_id, :release_type])
  end

  def migrate_source_key_monitor(source_key_project_monitor_id) do
    # migrate clouds
    CncfDashboardApi.GitlabMigrations.upsert_clouds()
    monitor = Repo.all(from skpm in CncfDashboardApi.SourceKeyProjectMonitor, 
                                        where: skpm.id == ^source_key_project_monitor_id) |> List.first
    # migrate project
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
                                                   where: skp.source_id == ^monitor.source_pipeline_id) |> List.first
    {:ok, monitor, source_key_project, source_key_pipeline}
  end

  def upsert_pipeline_monitor(source_key_project_monitor_id) do
    last_checked
    {:ok, monitor, source_key_project, source_key_pipeline} = migrate_source_key_monitor(source_key_project_monitor_id)
    
    # determine pipeline type
    case is_deploy_pipeline_type(source_key_project.new_id) do
      true -> pipeline_type = "deploy"
      _ -> pipeline_type = "build"
    end

    #Update pipeline_release_type

    # saved curl data (source key project monitor)                                                
    # field :source_project_id, :string
    # field :source_pipeline_id, :string
    # field :source_pipeline_job_id, :string
    # field :pipeline_release_type, :string
    # field :active, :boolean, default: true
    
    # pipeline monitor fields
    # field :pipeline_id, :integer
    # field :running, :boolean, default: false
    # field :release_type, :string
    # field :pipeline_type, :string
    # field :project_id, :integer

    alternate_release = if (monitor.pipeline_release_type == "stable"), do: "head", else: "stable"

    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      release_type: alternate_release} 
      |> find_by([:pipeline_id, :project_id, :release_type])

      case pm_found do
        :found -> raise "You may not monitor the same project and pipeline for two different branches"
        _ ->
      end
                                                           
    # Insert only if pipeline, project, and release type do not exist
    # else update
    {pm_found, pm_record} = %CncfDashboardApi.PipelineMonitor{pipeline_id: source_key_pipeline.new_id, 
      project_id: source_key_project.new_id,
      release_type: monitor.pipeline_release_type} 
      |> find_by([:pipeline_id, :project_id, :release_type])

    changeset = CncfDashboardApi.PipelineMonitor.changeset(pm_record, 
                                                           %{project_id: source_key_project.new_id,
                                                             pipeline_id: source_key_pipeline.new_id,
                                                             running: true,
                                                             release_type: monitor.pipeline_release_type,
                                                             pipeline_type: pipeline_type 
                                                           })

    case pm_found do
      :found ->
        {_, pm_record} = Repo.update(changeset) 
      :not_found ->
        {_, pm_record} = Repo.insert(changeset) 
    end

    # migrate all jobs for the pipeline 
    CncfDashboardApi.GitlabMigrations.upsert_pipeline_jobs(monitor.source_project_id |> String.to_integer, 
                                                           monitor.source_pipeline_id |> String.to_integer)

    # TODO if no build job status and cloud job status records for passed project, create/default to running or N/A

    # TODO put polling in caller i.e. controller
    #
    # TODO populate ref_monitor
    upsert_ref_monitor(source_key_project.new_id,source_key_pipeline.new_id)
    
    # Call dashboard channel
    CncfDashboardApi.Endpoint.broadcast! "dashboard:*", "new_cross_cloud_call", %{reply: dashboard_response} 

    Logger.info fn ->
      "GitlabMonitor: Broadcasted json"
    end

    # TODO update last updated

  end

  def dashboard_response do
    cloud_list = Repo.all(from cd1 in CncfDashboardApi.Clouds, 
                                           where: cd1.active == true,
                                           select: %{id: cd1.id, cloud_id: cd1.id, 
                                             name: cd1.cloud_name, cloud_name: cd1.cloud_name}) 
    projects = Repo.all(from projects in CncfDashboardApi.Projects,      
                                         left_join: ref_monitors in assoc(projects, :ref_monitors),
                                         left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                                         left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                                         where: projects.active == true,
                                         preload: [ref_monitors: 
                                                   {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                                     dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                                   }] )

    with_cloud = %{"clouds" => cloud_list, "projects" => projects} 
    response = CncfDashboardApi.DashboardView.render("index.json", dashboard: with_cloud)
  end

  # project name is either cross-cloud (cross-cloud handles the deploy pipelines)
  # or other (a build pipeline)
  def is_deploy_pipeline_type(project_id) do
    project = Repo.all(from skp in CncfDashboardApi.Projects, 
                                        where: skp.id == ^project_id) |> List.first
    if project.name =~ "cross-cloud" do
      true
    else
      false
    end

  end

  # projects, clouds, pipleines, and pipeline jobs should be recently migrated before calling build status 
  def build_status(pipeline_id) do
     # determine the build status
     #    i.e. get the build job (name = container)
     #    if exists, dashboard badge status status = build job status
     #    if doesn't exist, dashboard badge status = running
    container = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                                          where: pj.pipeline_id == ^pipeline_id)
                |> Enum.find(fn(x) -> x.name =~ "container" end) 
    if container && (container.status == "success" || container.status == "failed") do
      container.status
    else
      "running"
    end
  end

  def compile_url(pipeline_id) do
     # determine the build status
     #    i.e. get the build job (name = compile)
     #    if exists, dashboard badge status status = build job status
     #    if doesn't exist, dashboard badge status = running
     project = Repo.all(from projects in CncfDashboardApi.Projects, 
                                          left_join: pipelines in assoc(projects, :pipelines),     
                                          where: pipelines.id == ^pipeline_id) 
                                          |> List.first

    compile = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                                          where: pj.pipeline_id == ^pipeline_id)
                |> Enum.find(fn(x) -> x.name =~ "compile" end) 
    if compile do
      source_key_pipeline_jobs = Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelineJobs, 
                                                   where: skpj.new_id == ^compile.id) |> List.first
      Logger.info fn ->
        "compile local pipeline_id: #{pipeline_id} source key: #{inspect(source_key_pipeline_jobs)}"
      end
      # e.g.   https://gitlab.dev.cncf.ci/coredns/coredns/-/jobs/31525
      "#{project.web_url}/-/jobs/#{source_key_pipeline_jobs.source_id}"
    end
  end

  # project, pipeline, and pipeline jobs should be migrated before
  # calling upsert_ref_monitor
  # 1. source_key_project_monitor is called from a http post
  # 2. pipeline_monitor is created/updated during the http_post
  # 3. upsert_ref_monitor is called to set up the dashboard
  def upsert_ref_monitor(project_id, pipeline_id) do
      Logger.info fn ->
        "upsert_ref_monitor project id: #{project_id} pipeline_id: #{pipeline_id}"
      end

    # initialize the dashboard
    initialize_ref_monitor(project_id)

    # get project
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

    #  get all clouds
    clouds = Repo.all(from c in CncfDashboardApi.Clouds)

    # build ref_monitor
    #    Abstraction of one or more pipelines
     # field :ref, :string
     # field :status, :string
     # field :sha, :string
     # field :release_type, :string
     # field :project_id, :integer
     # field :order, :integer
     # field :pipeline_id, :integer
    if pipeline.release_type == "stable" do
      pipeline_order = 1
    else
      pipeline_order = 2
    end

    # if never given a release status for the pipeline, raise an error

    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id,
      release_type: pipeline_monitor.release_type} 
      |> find_by([:project_id, :release_type])

    changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
               %{ref: pipeline.ref,
                 status: pipeline.status,
                 sha: pipeline.sha,
                 release_type: pipeline_monitor.release_type,
                 project_id: project_id,
                 pipeline_id: pipeline.id,
                 order: pipeline_order
               })

    # if ref_monitor for project with a release type already exists, update
    #    else insert
    Logger.info fn ->
      "upsert_ref_monitor ref_monitor found?: #{inspect(rm_found)}"
    end
    case rm_found do
      :found ->
        {:ok, rm_record} = Repo.update(changeset) 
      :not_found ->
        {:ok, rm_record} = Repo.insert(changeset) 
    end
     
     # build dashboard_badget_status
     #   Abstraction of the status of one or more pipeline jobs
     # field :status, :string
     # field :cloud_id, :integer
     # field :ref_monitor_id, :integer
     # field :order, :integer
     #
     # et the dashboard badge for the build job
     #   i.e. get the dashboard badge with order = 1

     #
     # upsert the build status badge based on ref_monitor and order (always 1)
    Logger.info fn ->
      "upsert_ref_monitor rm_record.id : #{inspect(rm_record)}"
    end
    {dbs_found, dbs_record} = %CncfDashboardApi.DashboardBadgeStatus{ref_monitor_id: rm_record.id, order: 1} 
      |> find_by([:ref_monitor_id, :order])

    changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(dbs_record, 
               %{ref: pipeline.ref,
                 status: build_status(pipeline_id),
                 ref_monitor_id: rm_record.id,
                 url: compile_url(pipeline_id),
                 order: 1 # build badge always 1 
               })

    Logger.info fn ->
      "upsert_ref_monitor DashboardBadgeStatus.changeset : #{inspect(changeset)}"
    end

    case dbs_found do
      :found ->
        {_, dbs_record} = Repo.update(changeset) 
      :not_found ->
        {_, dbs_record} = Repo.insert(changeset) 
    end
     
     # TODO loop through all clouds
     #
     # TODO determine cloud status
     #    determine cloud_id of the job (or set of jobs) status
     #    set order to the cloud order
     #
  end

  # projects and clouds must be migrated before calling initialize_ref_monitor
  def initialize_ref_monitor(project_id) do
      Logger.info fn ->
        "initialize_ref_monitor: initializing"
      end
      
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "stable"} 
      |> find_by([:project_id, :release_type])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "stable", 1) # stable order is always 1
     _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'stable'"
      end
    end

    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "head"} 
      |> find_by([:project_id, :release_type])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "head", 2) # head order is always 2
     _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'head'"
      end
    end

  end

  def new_n_a_ref_monitor(project_id, release_type, ref_order) do
    # insert a stable ref_monitor
    changeset = CncfDashboardApi.RefMonitor.changeset(%CncfDashboardApi.RefMonitor{}, 
                                                      %{ref: "N/A",
                                                        status: "N/A",
                                                        sha: "N/A",
                                                        release_type: release_type,
                                                        project_id: project_id,
                                                        order: ref_order 
                                                      })
    {_, rm_record} = Repo.insert(changeset) 
    #      insert a databoard_badge for build status with status of N/A for the new ref_monitor
    changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(%CncfDashboardApi.DashboardBadgeStatus{}, 
                                                                %{ref: "N/A",
                                                                  status: "N/A",
                                                                  ref_monitor_id: rm_record.id,
                                                                  order: 1 # build badge always 1 
                                                                })
    {_, dbs_record} = Repo.insert(changeset) 
    #  get all clouds
    Repo.all(from c in CncfDashboardApi.Clouds, order_by: :order)
    # insert one dashboard_badge for each cloud with status of N/A for the new ref_monitor
    |> Enum.map(fn(x) -> 
      Logger.info fn ->
        "initialize_ref_monitor cloud: #{inspect(x)}"
      end
      cloud_order = x.order + 2 # clouds start with 2 wrt badge status
      changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(%CncfDashboardApi.DashboardBadgeStatus{}, 
                                                                  %{ref: "N/A",
                                                                    status: "N/A",
                                                                    ref_monitor_id: rm_record.id,
                                                                    order: cloud_order })
      {_, dbs_record} = Repo.insert(changeset) 

    end) 
  end

end
