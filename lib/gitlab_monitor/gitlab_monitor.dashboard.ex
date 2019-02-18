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
  def new_n_a_ref_monitor(project_id, release_type, ref_order) do
    Logger.info fn -> 
      "new_n_a_ref_monitor project_id, release_type, ref_order: #{inspect(project_id)} #{inspect(release_type)} #{inspect(ref_order)}" 
    end
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
 
  A pipeline monitor could be a deploy pipeline or build pipeline
  Target denotes the source project (original build pipeline that triggered the deployment pipelines)
  Only the target has its information displayed on the ref_monitor
  target_pm corresponds to target pipeline monitor
  target_pl corresponds to target pipeline 

  Returns `%RefMonitor`
  """
  def upsert_ref_monitor(pipeline_monitor, target_pm, target_pl, pipeline_order) do
    #TODO remove pipeline_monitor
      Logger.info fn ->
        "upsert_ref_monitor pipeline_monitor, target_pm, target_pl, pipeline_order: #{inspect(pipeline_monitor)}, #{inspect(target_pm)},
        #{inspect(target_pl)}, #{inspect(pipeline_order)}"
      end
    {rm_found, rm_record} = %CncfDashboardApi.RefMonitor{project_id: target_pm.project_id,
      release_type: target_pm.release_type} 
      |> find_by([:project_id, :release_type])

    Logger.info fn ->
      "upsert_ref_monitor rm_found, rm_record: #{inspect(rm_found)}, #{inspect(rm_record)}"
    end
    changeset = CncfDashboardApi.RefMonitor.changeset(rm_record,  
                                                      %{ref: target_pl.ref,
                                                        status: target_pl.status,
                                                        sha: target_pl.sha,
                                                        release_type: target_pm.release_type,
                                                        project_id: target_pm.project_id,
                                                        pipeline_id: target_pl.id,
                                                        order: pipeline_order
                                                      })
    Logger.info fn ->
      "upsert_ref_monitor changeset: #{inspect(changeset)}"
    end

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
