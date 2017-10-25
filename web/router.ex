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


  # Other scopes may use custom stacks.
  scope "/api", CncfDashboardApi do
    pipe_through :api
    resources "/projects", ProjectsController, except: [:new, :edit]   
    resources "/source_key_projects", SourceKeyProjectsController, except: [:new, :edit]   
    resources "/pipelines", PipelinesController, except: [:new, :edit]
    resources "/source_key_pipelines", SourceKeyPipelinesController, except: [:new, :edit]   
    resources "/pipeline_jobs", PipelineJobsController, except: [:new, :edit]
    resources "/source_key_pipeline_jobs", SourceKeyPipelineJobsController, except: [:new, :edit]
    resources "/clouds", CloudsController, except: [:new, :edit] 
    resources "/dashboard", DashboardController, only: [:index]   
  end
end
