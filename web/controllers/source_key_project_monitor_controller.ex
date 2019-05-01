require IEx;
require Logger;
defmodule CncfDashboardApi.SourceKeyProjectMonitorController do
  use CncfDashboardApi.Web, :controller

  alias CncfDashboardApi.SourceKeyProjectMonitor

  def index(conn, _params) do
    source_key_project_monitor = Repo.all(SourceKeyProjectMonitor)
    render(conn, "index.json", source_key_project_monitor: source_key_project_monitor)
  end

  def create(conn, %{"source_key_project_monitor" => source_key_project_monitor_params}) do
    Logger.info fn ->
      "SourceKeyProjectMonitorController source_key_project_monitor_params: #{inspect(source_key_project_monitor_params)}"
    end
    changeset = SourceKeyProjectMonitor.changeset(%SourceKeyProjectMonitor{}, source_key_project_monitor_params)

    case Repo.insert(changeset) do
      {:ok, source_key_project_monitor} ->
        # start polling
        CncfDashboardApi.GitlabMonitor.upsert_pipeline_monitor(source_key_project_monitor.id)
        {_pm_found, pm_record} = CncfDashboardApi.GitlabMonitor.PipelineMonitor.pipeline_monitor(source_key_project_monitor.id) 
        project = Repo.get!(CncfDashboardApi.Projects, pm_record.project_id)
        Logger.info fn ->
          "source_key_project_monitor create project: #{inspect(project)}"
        end
        
        case pm_record.pipeline_type  do
          "build" ->
            Logger.info fn ->
              "source_key_project_monitor start_pipeline build skpm.source_pipeline_id, skpm.id timeout: #{inspect({source_key_project_monitor.source_pipeline_id, 
                  source_key_project_monitor.id, 
                  project.timeout})}"
            end
                CncfDashboardApi.Polling.Supervisor.Pipeline.start_pipeline(source_key_project_monitor.source_pipeline_id, 
                  source_key_project_monitor.id, 
                  project.timeout * 1000) 
            # Process.sleep(13000)
          n when n in ["deploy", "provision"] ->
            config = CncfDashboardApi.YmlReader.GitlabCi.gitlab_pipeline_config()
            cc = Enum.find(config, fn(x) -> x["pipeline_name"] == project.name end) 
            Logger.info fn ->
              "source_key_project_monitor deploy  skpm.project_build_pipeline_id skpm.source_project_id skpm.cloud skpm target_project_name skpm.id timeout: #{inspect({source_key_project_monitor.project_build_pipeline_id, 
                  source_key_project_monitor.source_project_id, 
                  source_key_project_monitor.cloud, 
                  source_key_project_monitor.target_project_name, 
                  source_key_project_monitor.id, 
                  cc["timeout"]})}"
            end
            # base unique identifier on the target's source_pipeline_id (e.g. a head or stable pipeline)), source_project_id (cross cloud or cross project), cloud (e.g. aws) , and target project name (e.g. linkerd)
            # i.e. '{"cross-project", "linkerd"}
                CncfDashboardApi.Polling.Supervisor.Pipeline.start_pipeline({source_key_project_monitor.project_build_pipeline_id, 
                  source_key_project_monitor.source_project_id, 
                  source_key_project_monitor.cloud, 
                  source_key_project_monitor.target_project_name}, 
                  source_key_project_monitor.id, 
                  cc["timeout"] * 1000) 
        end

        conn
        |> put_status(:created)
        |> put_resp_header("location", source_key_project_monitor_path(conn, :show, source_key_project_monitor))
        |> render("show.json", source_key_project_monitor: source_key_project_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    source_key_project_monitor = Repo.get!(SourceKeyProjectMonitor, id)
    render(conn, "show.json", source_key_project_monitor: source_key_project_monitor)
  end

  def update(conn, %{"id" => id, "source_key_project_monitor" => source_key_project_monitor_params}) do
    source_key_project_monitor = Repo.get!(SourceKeyProjectMonitor, id)
    changeset = SourceKeyProjectMonitor.changeset(source_key_project_monitor, source_key_project_monitor_params)

    case Repo.update(changeset) do
      {:ok, source_key_project_monitor} ->
        render(conn, "show.json", source_key_project_monitor: source_key_project_monitor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CncfDashboardApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    source_key_project_monitor = Repo.get!(SourceKeyProjectMonitor, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(source_key_project_monitor)

    send_resp(conn, :no_content, "")
  end
end
