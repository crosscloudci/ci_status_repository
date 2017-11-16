defmodule CncfDashboardApi.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: CncfDashboardApi.Repo

  def cloud_factory do
    %CncfDashboardApi.Clouds{
      cloud_name: "aws",
      order: 1, 
      active: true 
    }
  end
  def dashboard_badge_status_factory do
    %CncfDashboardApi.DashboardBadgeStatus{
      # name: "Kubernetes",
      status: "success",
      # ref: "ci_master",
      cloud: build(:cloud),
    }
	end
  def ref_monitor_factory do
    %CncfDashboardApi.RefMonitor{
      ref: "ci_master",
      status: "success",
      sha: "2342342342343243sdfsdfsdfs",
      release_type: "build",
      dashboard_badge_statuses: [build(:dashboard_badge_status)],
    }

	end
  def pipeline_job_factory do
    %CncfDashboardApi.PipelineJobs{
      name: "Kubernetes",
      status: "success",
      ref: "ci_master",
      cloud: build(:cloud),
    }
	end
  def pipeline_factory do
    %CncfDashboardApi.Pipelines{
      ref: "ci_master",
      status: "success",
      sha: "2342342342343243sdfsdfsdfs",
      release_type: "build",
      pipeline_jobs: [build(:pipeline_job)],
    }

	end
  def project_factory do
    %CncfDashboardApi.Projects{
      name: "Kubernetes",
      ssh_url_to_repo: "http://kubernetes.io/",
      http_url_to_repo: "http://kubernetes.io/",
      active: true,
      logo_url: "https://www.cncf.io/wp-content/uploads/2016/09/ico_kubernetes-100x100.png",
      display_name: "Kubernetes",
      sub_title: "Kub",
      yml_name: "Kubernetes",
      yml_gitlab_name: "kubernetes",
      project_url: "http://kubernetes.io/",
      pipelines: [build(:pipeline)],
      ref_monitors: [build(:ref_monitor)],
    }
	end

    # field :source_project_id, :string
    # field :source_pipeline_id, :string
    # field :source_pipeline_job_id, :string
    # field :pipeline_release_type, :string
    # field :active, :boolean, default: true
  def source_key_project_monitor_factory do
    %CncfDashboardApi.SourceKeyProjectMonitor{
      source_project_id: "1",
      source_pipeline_id: "1",
      source_pipeline_job_id: "1",
      pipeline_release_type: "stable",
      active: true, 
    }

	end

end
