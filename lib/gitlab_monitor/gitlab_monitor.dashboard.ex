require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor.Dashboard do 
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo

 @doc """
  Creates a new ref monitor based on `project_id`, `release_type`, and `ref_order`.

  All statues start out as N/A 

  Returns `[:ok]`
  """
  def new_n_a_ref_monitor(project_id, release_type, test_env, ref_order, kubernetes_release_type, arch) do
    Logger.info fn -> 
      "new_n_a_ref_monitor project_id, release_type, test_env,  ref_order kubernetes_release_type arch: #{inspect(project_id)} #{inspect(release_type)} #{inspect(test_env)} #{inspect(ref_order)} #{inspect(kubernetes_release_type)} #{inspect(arch)}" 
    end
    # insert a ref_monitor
    changeset = CncfDashboardApi.RefMonitor.changeset(%CncfDashboardApi.RefMonitor{}, 
                                                      %{ref: "N/A",
                                                        status: "N/A",
                                                        sha: "N/A",
                                                        release_type: release_type,
                                                        kubernetes_release_type: kubernetes_release_type,
                                                        arch: arch,
                                                        test_env: test_env,
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
    Repo.all(from c in CncfDashboardApi.Clouds, where: c.active == true,
             order_by: :order)
             # insert one dashboard_badge for each cloud with status of N/A for the new ref_monitor
             |> Enum.map(fn(x) -> 
               # Logger.info fn ->
               #   "new dashboard badge status cloud: #{inspect(x)}"
               # end
               cloud_order = x.order + 1 # clouds start with 2 wrt badge status
               changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(%CncfDashboardApi.DashboardBadgeStatus{}, 
                                                                           %{ref: "N/A",
                                                                             status: "N/A",
                                                                             cloud_id: x.id,
                                                                             ref_monitor_id: rm_record.id,
                                                                             order: cloud_order })
                                                                             {_, dbs_record} = Repo.insert(changeset) 
               # Logger.info fn ->
               #   "new initialized dashboard badge status: #{inspect(dbs_record)}"
               # end

             end) 
  end

 @doc """
  Creates a new set of ref monitors based on an internal `project_id`.

  Four ref_monitors (two for stable, two for head) are created per project.

  Projects and clouds must be migrated before calling initialize_ref_monitor

  Returns `[:ok]`
  """
  def initialize_ref_monitor(project_id) do
    Logger.info fn ->
      "initialize_ref_monitor: initializing"
    end

    CncfDashboardApi.GitlabMonitor.PMToDashboard.pipeline_types() |> Enum.map(fn(pt) ->

      {p_found, p_record} = %CncfDashboardApi.Projects{id: project_id, 
        name: "Kubernetes"} |> find_by([:id, :name])
      # The Kubernetes cluster must match the Kubernetes binaries
      # i.e. there are no 'head' Kubenenetes binaries installed on a
      # 'stable' Kubernetes cluster
      if (p_found == :found and 
        pt.project_release_type == pt.kubernetes_release_type) ||
          (p_found == :not_found) do
        {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, 
          release_type: pt.project_release_type, 
          kubernetes_release_type: pt.kubernetes_release_type, 
          arch: pt.arch, 
          test_env: pt.kubernetes_release_type} |> find_by([:project_id, :release_type, :kubernetes_release_type, :arch, :test_env])

        case rm_found do
          :not_found ->
            new_n_a_ref_monitor(project_id, pt.project_release_type, pt.kubernetes_release_type, pt.order, pt.kubernetes_release_type, pt.arch) 
          _ -> 
            Logger.info fn ->
              "initialize_ref_monitor: release_types/test_env/arch already exists for project_id: #{project_id} pipeline type: #{inspect(pt)}"
            end
        end
      end
    end)
  end

 @doc """
  Prepares a complete dashboard json response.
  Returns the dashboard json 
  """
  def dashboard_response do
    yml = System.get_env("GITLAB_CI_YML")
    {d_found, d_record} = %CncfDashboardApi.Dashboard{gitlab_ci_yml: yml } |> find_by([:gitlab_ci_yml])
    cncf_relations = CncfDashboardApi.YmlReader.GitlabCi.cncf_relations_list()
    cloud_list = Repo.all(from cd1 in CncfDashboardApi.Clouds, 
                          where: cd1.active == true,
                          order_by: [cd1.order]) 
    projects = Repo.all(from projects in CncfDashboardApi.Projects,      
                        left_join: ref_monitors in assoc(projects, :ref_monitors),
                        left_join: dashboard_badge_statuses in assoc(ref_monitors, :dashboard_badge_statuses),
                        left_join: cloud in assoc(dashboard_badge_statuses, :cloud),
                        where: projects.active == true,
                        order_by: [projects.order, ref_monitors.order, dashboard_badge_statuses.order], 
                        preload: [ref_monitors: 
                                  {ref_monitors, dashboard_badge_statuses: dashboard_badge_statuses, 
                                    dashboard_badge_statuses: {dashboard_badge_statuses, cloud: cloud },
                                  }] )

    with_cloud = %{"dashboard" => d_record, 
      "clouds" => cloud_list, 
      "projects" => projects, 
      "cncf_relations" => cncf_relations} 
    response = CncfDashboardApi.DashboardView.render("dashboard.json", dashboard: with_cloud)
  end

  @doc """
  Broadcasts the entire dashboard to the front end.
  Returns :ok 
  """
  def broadcast do
    # Call dashboard channel
    CncfDashboardApi.Endpoint.broadcast! "dashboard:*", "new_cross_cloud_call", %{reply: dashboard_response} 

    Logger.info fn ->
      "GitlabMonitor: Broadcasted json"
    end
    :ok
  end

 @doc """
  Updates or inserts a ref_monitor based on `pipeline_monitor`, `target_pm`, `target_pl`, and `pipeline_order`.
 
  The set of ref monitors should be assumed to be initialized from `CncfDashboardApi.GitlabMonitor.PMToDashboard.pipeline_types()` 
  for every project
  A pipeline monitor could be a deploy pipeline, build pipeline, or provision pipeline
  Target denotes the source project (original build pipeline that triggered the deployment pipelines)
  Only the target has its information displayed on the ref_monitor
  target_pm corresponds to target pipeline monitor
  target_pl corresponds to target pipeline 

  Returns `%RefMonitor`
  """
  def upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, pipeline_order, test_env, arch) do
    #TODO remove pipeline_monitor
    Logger.info fn ->
      "upsert_ref_monitor pipeline_monitor, target_pm, target_pl, pipeline_order: #{inspect(pipeline_monitor)}, #{inspect(target_pm)},
      #{inspect(target_pl)}, #{inspect(pipeline_order)}"
    end
    case pipeline_monitor.pipeline_type do
      #TODO Get the ref (or status?) dynamically based on pipeline_monitor type
      # if build -> ref comes from target pipeline
        # if provision, ref comes from a retrieved build pipeline
        # if deploy ref comes from target pipeline
      "build" ->
        # loop through all ref monitors and update the builds (for all drop downs)
        kubernetes_release_type = test_env 
        # there is no test_env for builds.  set to passed env
        derived_test_env = test_env
        derived_arch = arch 
        ref = target_pl.ref
        sha = target_pl.sha
      "provision" ->
        #  kubernetes release type is either the regular release type on a provision
        # project monitor or the release type on its build (kubernetes) project monitor
        kubernetes_release_type = target_pm.release_type
        derived_test_env = target_pm.release_type
        derived_arch = pipeline_monitor.arch
        build_pl = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
          where: pm1.id == ^pipeline_monitor.internal_build_pipeline_id ) |> List.first
        ref = build_pl.ref
        sha = build_pl.sha
      "deploy" ->
        provision_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.provision_pipeline_monitor_by_deploy_pipeline_monitor(pipeline_monitor)
        Logger.info fn ->
          "upsert_ref_monitor provision_pm: #{inspect(provision_pm)}"
        end
        derived_test_env = provision_pm.release_type
        kubernetes_release_type = provision_pm.release_type
        derived_arch = provision_pm.arch
        build_pl = Repo.all(from pm1 in CncfDashboardApi.Pipelines, 
          where: pm1.id == ^pipeline_monitor.internal_build_pipeline_id ) |> List.first
        ref = build_pl.ref
        sha = build_pl.sha
      _ ->
        :ok
    end
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
      release_type: target_pm.release_type, kubernetes_release_type: kubernetes_release_type, test_env: derived_test_env, arch: derived_arch} 
      |> find_by([:project_id, :release_type, :kubernetes_release_type, :test_env, :arch])
      changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
                                                        %{ref: ref,
                                                          status: target_pl.status,
                                                          sha: sha,
                                                          release_type: target_pm.release_type,
                                                          kubernetes_release_type: kubernetes_release_type,
                                                          arch: derived_arch,
                                                          test_env: derived_test_env,
                                                          project_id: target_pm.project_id,
                                                          pipeline_id: target_pl.id,
                                                          order: pipeline_order
                                                        })
      
       case rm_found do
         :found ->
          {:ok, rm_record} = Repo.update(changeset) 
          Logger.info fn ->
            "ref_monitor found update: #{inspect(rm_record)}"
          end
        :not_found ->
          {:ok, rm_record} = Repo.insert(changeset) 
        Logger.error fn ->
          "ref_monitor not found insert (should never happen): #{inspect(rm_record)}"
        end
       end
       rm_record
  end

 @doc """
  Updates dashboard badge status based on `record_pm`, `ref`, `status`, `url`, and `badge_order`.

  Returns `%DashboardBadgeStatus`
  """
  def update_badge(rm_record, ref, status, url, badge_order, cloud_id \\ nil) do
    {dbs_found, dbs_record} = %CncfDashboardApi.DashboardBadgeStatus{ref_monitor_id: rm_record.id, order: badge_order} 
                              |> find_by([:ref_monitor_id, :order])

    changeset = CncfDashboardApi.DashboardBadgeStatus.changeset(dbs_record, 
                                                                %{ref: ref,
                                                                  status: status,
                                                                  ref_monitor_id: rm_record.id,
                                                                  url: url,
                                                                  order: badge_order, # build badge always 1
                                                                  cloud_id: cloud_id # build badge has no cloud_id 
                                                                })

    Logger.info fn ->
      "update_badge DashboardBadgeStatus.changeset : #{inspect(changeset)}"
    end

    case dbs_found do
      :found ->
        {_, dbs_record} = Repo.update(changeset) 
      Logger.info fn ->
        "dashboard status found update: #{inspect(dbs_record)}"
      end
      :not_found ->
        {_, dbs_record} = Repo.insert(changeset) 
      Logger.error fn ->
        "dashboard status not found insert (should never happen): #{inspect(dbs_record)}"
      end
    end
    dbs_record
  end
  
 @doc """
  Updates the last checked time on the dashboard.

  Returns `%Dashboard`
  """
  def last_checked do
    yml = System.get_env("GITLAB_CI_YML")
    {d_found, d_record} = %CncfDashboardApi.Dashboard{gitlab_ci_yml: yml } |> find_by([:gitlab_ci_yml])
    changeset = CncfDashboardApi.Dashboard.changeset(d_record, %{last_check: Ecto.DateTime.utc, gitlab_ci_yml: yml})
    case d_found do
      :found ->
        {_, d_record} = Repo.update(changeset) 
      :not_found ->
        {_, d_record} = Repo.insert(changeset) 
    end
    d_record
  end
end
