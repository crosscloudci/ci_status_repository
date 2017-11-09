defmodule CncfDashboardApi.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: CncfDashboardApi.Repo

  def cloud_factory do
    %CncfDashboardApi.Clouds{
      cloud_name: "aws"
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
      pipelines: [build(:pipelines)],
    }
	end

end
