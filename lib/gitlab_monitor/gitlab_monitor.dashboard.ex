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
    # insert a stable ref_monitor
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

  Two ref_monitors (one for stable, one for head) are created per project.

  Projects and clouds must be migrated before calling initialize_ref_monitor

  Returns `[:ok]`
  """
  def initialize_ref_monitor(project_id) do
    Logger.info fn ->
      "initialize_ref_monitor: initializing"
    end

    # https://github.com/vulk/cncf_ci/issues/29
    # Add test environment field to the database
    # To add rows either: 
    #   1) pass test environment field in dynamically
    #   2) fill out all possible test environment 'rows'
    #     -- for #29 this means four hard coded entries:
    #       --  test environment 'head', project ref 'head'
    #       --  test environment 'head', project ref 'stable'
    #       --  test environment 'stable', project ref 'head'
    #       --  test environment 'stable', project ref 'stable'
    #   3) Probably pick (2) until test enviroments are enumerated in the yml file in a future
    #   ticket (arm?) (hence not dynamic

    # need a way to insert 4 empty builds *without* test env and then retreive them later ...
    # stable, stable
    # {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "stable", test_env: "stable", kubernetes_release_type: "stable", arch: "amd64"} 
    #                         |> find_by([:project_id, :release_type, :test_env, :kubernetes_release_type, :arch])
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "stable", test_env: "stable"} 
                            |> find_by([:project_id, :release_type, :test_env])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "stable", "stable", 1, "stable", "amd64") # stable, stable order is always 1
      _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'stable' test_env 'stable'"
      end
    end

    # head, stable
    # {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "head", test_env: "stable", kubernetes_release_type: "stable", arch: "amd64"} 
    #                         |> find_by([:project_id, :release_type, :test_env, :kubernetes_release_type, :arch])
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "head", test_env: "stable"} 
                            |> find_by([:project_id, :release_type, :test_env])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "head", "stable", 2, "stable", "amd64") # head, stable order is always 2
      _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'head' test end 'stable'"
      end
    end

    # head, head 
    # {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "head", test_env: "head", kubernetes_release_type: "head", arch: "amd64"} 
    #                         |> find_by([:project_id, :release_type, :test_env, :kubernetes_release_type, :arch])
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "head", test_env: "head"} 
                            |> find_by([:project_id, :release_type, :test_env])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "head", "head", 3, "head", "amd64") # head, stable order is always 3
      _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'head' test end 'head'"
      end
    end

    # stable, head 
    # {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "stable", test_env: "head", kubernetes_release_type: "head", arch: "amd64"} 
    #                         |> find_by([:project_id, :release_type, :test_env, :kubernetes_release_type, :arch])
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: project_id, release_type: "stable", test_env: "head"} 
                            |> find_by([:project_id, :release_type, :test_env])
    case rm_found do
      :not_found ->
        new_n_a_ref_monitor(project_id, "stable", "head", 4, "head", "amd64") # head, stable order is always 4
      _ -> 
      Logger.info fn ->
        "initialize_ref_monitor: Stable already exists for project_id: #{project_id} release type 'stable' test end 'head'"
      end
    end

  end

 @doc """
  Prepares a complete dashboard json response.
  Returns the dashboard json 
  """
  def dashboard_response do
    yml = System.get_env("GITLAB_CI_YML")
    {d_found, d_record} = %CncfDashboardApi.Dashboard{gitlab_ci_yml: yml } |> find_by([:gitlab_ci_yml])
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

    with_cloud = %{"dashboard" => d_record, "clouds" => cloud_list, "projects" => projects} 
    response = CncfDashboardApi.DashboardView.render("index.json", dashboard: with_cloud)
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
 
  The set of ref monitors should be assumed to be initialized as follows 
  for every project
  --  test environment 'stable', project ref 'stable', pipeline_order = 1
  --  test environment 'stable', project ref 'head', pipeline_order = 2
  --  test environment 'head', project ref 'head', pipeline_order = 3
  --  test environment 'head', project ref 'stable', pipeline_order = 4
  A pipeline monitor could be a deploy pipeline or build pipeline
  Target denotes the source project (original build pipeline that triggered the deployment pipelines)
  Only the target has its information displayed on the ref_monitor
  target_pm corresponds to target pipeline monitor
  target_pl corresponds to target pipeline 

  Returns `%RefMonitor`
  """
  def upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, pipeline_order, test_env) do
    #TODO remove pipeline_monitor
    Logger.info fn ->
      "upsert_ref_monitor pipeline_monitor, target_pm, target_pl, pipeline_order: #{inspect(pipeline_monitor)}, #{inspect(target_pm)},
      #{inspect(target_pl)}, #{inspect(pipeline_order)}"
    end
    # if a build pipeline monitor, must update all of the build ref_monitors ..
    # we should be passed in an order
    #       --  test environment 'stable', project ref 'stable' = 1
    #       --  test environment 'stable', project ref 'head' = 2
    #       --  test environment 'head', project ref 'head' = 3
    #       --  test environment 'head', project ref 'stable' = 4
    # if a provision monitor, should skip (no updates for provisioning)
    # if a deploy monitor, should update the ref monitor for that project, release_type, kubernetes_release_type/test_env combo
    # if pipeline_monitor.pipeline_type == "deploy" do
    #   provision_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.provision_pipeline_monitor_by_deploy_pipeline_monitor(pipeline_monitor)
    #   Logger.info fn ->
    #     "upsert_ref_monitor provision_pm: #{inspect(provision_pm)}"
    #   end
    #   test_env = provision_pm.release_type
    #   kubernetes_release_type = provision_pm.release_type
    #   arch = provision_pm.arch
    # else
    #   kubernetes_release_type = pipeline_monitor.kubernetes_release_type
    # end
    # kubernetes_release_type = pipeline_monitor.kubernetes_release_type
    case pipeline_monitor.pipeline_type do
      "build" ->
        # loop through all ref monitors and update the builds (for all drop downs)
        if target_pm.target_project_name == "kubernetes" do
          kubernetes_release_type = target_pm.release_type
        else
          kubernetes_release_type = test_env 
        end
        {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
          # release_type: target_pm.release_type, test_env: test_env, kubernetes_release_type: pipeline_monitor.kubernetes_release_type, arch: pipeline_monitor.arch} 
          release_type: target_pm.release_type, test_env: test_env} 
          |> find_by([:project_id, :release_type, :test_env])
          # |> find_by([:project_id, :release_type, :test_env, :kubernetes_release_type, :arch])
          changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
                                                            %{ref: target_pl.ref,
                                                              status: target_pl.status,
                                                              sha: target_pl.sha,
                                                              release_type: target_pm.release_type,
                                                              kubernetes_release_type: kubernetes_release_type,
                                                              arch: pipeline_monitor.arch,
                                                              test_env: test_env,
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
        # rm_records = CncfDashboardApi.Repo.all(from rm in CncfDashboardApi.RefMonitor,
        #                                        where: rm.project_id == ^target_pm.project_id,
        #                                        where: rm.release_type == ^target_pm.release_type, 
        #                                        where: rm.test_env == ^test_env, 
        #                                        where: rm.kubernetes_release_type == ^test_env) 
        #                                        # where: rm.arch == ^pipeline_monitor.arch) 
        #
        # Logger.info fn ->
        #   "upsert_ref_monitor rm_records: #{inspect(rm_records)}"
        # end
        # Enum.each(rm_records, fn(rm_record) ->
        #   changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
        #                                                     %{ref: target_pl.ref,
        #                                                       status: target_pl.status,
        #                                                       # sha: target_pl.sha,
        #                                                       # release_type: target_pm.release_type,
        #                                                       # kubernetes_release_type: pipeline_monitor.kubernetes_release_type,
        #                                                       # arch: pipeline_monitor.arch,
        #                                                       # test_env: test_env,
        #                                                       # project_id: target_pm.project_id,
        #                                                       # pipeline_id: target_pl.id,
        #                                                       # order: pipeline_order
        #                                                     })
        #   Logger.info fn ->
        #     "upsert_ref_monitor changeset: #{inspect(changeset)}"
        #   end
        #
        #   # case rm_found do
        #   #   :found ->
        #       {:ok, rm_record} = Repo.update(changeset) 
        #     # Logger.info fn ->
        #     #   "ref_monitor found update: #{inspect(rm_record)}"
        #     # end
        #     # :not_found ->
        #     #   {:ok, rm_record} = Repo.insert(changeset) 
        #     # Logger.error fn ->
        #     #   "ref_monitor not found insert (should never happen): #{inspect(rm_record)}"
        #     # end
        #   # end
        #   rm_record
        # end)
      "provision" ->
        {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
          release_type: target_pm.release_type, test_env: test_env} 
          |> find_by([:project_id, :release_type, :test_env])
          changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
                                                            %{ref: target_pl.ref,
                                                              status: target_pl.status,
                                                              sha: target_pl.sha,
                                                              release_type: target_pm.release_type,
                                                              kubernetes_release_type: target_pm.release_type,
                                                              arch: pipeline_monitor.arch,
                                                              test_env: target_pm.release_type,
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
      "deploy" ->
        provision_pm = CncfDashboardApi.GitlabMonitor.PipelineMonitor.provision_pipeline_monitor_by_deploy_pipeline_monitor(pipeline_monitor)
        Logger.info fn ->
          "upsert_ref_monitor provision_pm: #{inspect(provision_pm)}"
        end
        test_env = provision_pm.release_type
        kubernetes_release_type = provision_pm.release_type
        arch = provision_pm.arch
        {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
          release_type: target_pm.release_type, test_env: test_env} 
          |> find_by([:project_id, :release_type, :test_env])
          changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
                                                            %{ref: target_pl.ref,
                                                              status: target_pl.status,
                                                              sha: target_pl.sha,
                                                              release_type: target_pm.release_type,
                                                              kubernetes_release_type: kubernetes_release_type,
                                                              arch: arch,
                                                              test_env: test_env,
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
      _ ->
        :ok
    end
    # {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
    #   release_type: target_pm.release_type, test_env: test_env, kubernetes_release_type: pipeline_monitor.kubernetes_release_type, arch: pipeline_monitor.arch} 
    #   |> find_by([:project_id, :release_type, :test_env, :kubernetes_release_type, :arch])
    # {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
    #   release_type: target_pm.release_type, test_env: test_env} 
    #   |> find_by([:project_id, :release_type, :test_env])
    #
    # Logger.info fn ->
    #   "upsert_ref_monitor rm_found, rm_record: #{inspect(rm_found)}, #{inspect(rm_record)}"
    # end
    # changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
    #                                                   %{ref: target_pl.ref,
    #                                                     status: target_pl.status,
    #                                                     sha: target_pl.sha,
    #                                                     release_type: target_pm.release_type,
    #                                                     kubernetes_release_type: pipeline_monitor.kubernetes_release_type,
    #                                                     arch: pipeline_monitor.arch,
    #                                                     test_env: test_env,
    #                                                     project_id: target_pm.project_id,
    #                                                     pipeline_id: target_pl.id,
    #                                                     order: pipeline_order
    #                                                   })
    # Logger.info fn ->
    #   "upsert_ref_monitor changeset: #{inspect(changeset)}"
    # end
    #
    # case rm_found do
    #   :found ->
    #     {:ok, rm_record} = Repo.update(changeset) 
    #   Logger.info fn ->
    #     "ref_monitor found update: #{inspect(rm_record)}"
    #   end
    #   :not_found ->
    #     {:ok, rm_record} = Repo.insert(changeset) 
    #   Logger.error fn ->
    #     "ref_monitor not found insert (should never happen): #{inspect(rm_record)}"
    #   end
    # end
    # rm_record
  end

 @doc """
  Updates dashboard badge status based on `record_pm`, `ref`, `status`, `url`, and `badge_order`.

  Returns `%DashboardBadgeStatus`
  """
  # def update_badge(rm_record, ref, status, url, badge_order) do
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
      "upsert_ref_monitor DashboardBadgeStatus.changeset : #{inspect(changeset)}"
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
         # Repo.update!(changeset) 
      :not_found ->
        {_, d_record} = Repo.insert(changeset) 
         # Repo.insert!(changeset) 
    end
    d_record
  end
end
