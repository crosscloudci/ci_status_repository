defmodule CncfDashboardApi.Router do
  use CncfDashboardApi.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CncfDashboardApi do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  pipeline :guardian do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
    plug Guardian.Plug.EnsureAuthenticated
  end 

  scope "/api", CncfDashboardApi do
    pipe_through [:api]
    resources "/dashboard", DashboardController, only: [:index]   
  end
  # Other scopes may use custom stacks.
  scope "/api", CncfDashboardApi do
    pipe_through [:api, :guardian]
    resources "/projects", ProjectsController, except: [:new, :edit]   
    resources "/source_key_projects", SourceKeyProjectsController, except: [:new, :edit]   
    resources "/pipelines", PipelinesController, except: [:new, :edit]
    resources "/source_key_pipelines", SourceKeyPipelinesController, except: [:new, :edit]   
    resources "/pipeline_jobs", PipelineJobsController, except: [:new, :edit]
    resources "/source_key_pipeline_jobs", SourceKeyPipelineJobsController, except: [:new, :edit]
    resources "/clouds", CloudsController, except: [:new, :edit] 
    resources "/source_key_project_monitor", SourceKeyProjectMonitorController, except: [:new, :edit]
    resources "/cloud_job_status", CloudJobStatusController, except: [:new, :edit]
    resources "/build_job_status", BuildJobStatusController, except: [:new, :edit]
    resources "/pipeline_monitor", PipelineMonitorController, except: [:new, :edit]
    resources "/ref_monitor", RefMonitorController, except: [:new, :edit]
    resources "/dashboard_badge_status", DashboardBadgeStatusController, except: [:new, :edit]
  end
end
