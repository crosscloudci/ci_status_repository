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
    first_cloud = CncfDashboardApi.Repo.all(CncfDashboardApi.Clouds) |> List.first
    if first_cloud do
      cloud = first_cloud
    else
      cloud = insert(:cloud)
    end
    %CncfDashboardApi.DashboardBadgeStatus{
      # name: "Kubernetes",
      status: "success",
      # ref: "ci_master",
      cloud_id: cloud.id,
    }
	end
  def ref_monitor_factory do
    %CncfDashboardApi.RefMonitor{
      ref: "ci_master",
      status: "success",
      sha: "2342342342343243sdfsdfsdfs",
      release_type: "stable",
      dashboard_badge_statuses: [build(:dashboard_badge_status)],
    }

	end
  def pipeline_job_factory do
    first_cloud = CncfDashboardApi.Repo.all(CncfDashboardApi.Clouds) |> List.first
    if first_cloud do
      cloud = first_cloud
    else
      cloud = insert(:cloud)
    end
    %CncfDashboardApi.PipelineJobs{
      name: "Kubernetes",
      status: "success",
      ref: "ci_master",
      cloud_id: cloud.id,
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

  def e2e_pipeline_job_factory do
    first_cloud = CncfDashboardApi.Repo.all(CncfDashboardApi.Clouds) |> List.first
    if first_cloud do
      cloud = first_cloud
    else
      cloud = insert(:cloud)
    end
    %CncfDashboardApi.PipelineJobs{
      name: "e2e",
      status: "running",
      ref: "ci_master",
      cloud_id: cloud.id,
    }
	end
  def app_deploy_pipeline_job_factory do
    first_cloud = CncfDashboardApi.Repo.all(CncfDashboardApi.Clouds) |> List.first
    if first_cloud do
      cloud = first_cloud
    else
      cloud = insert(:cloud)
    end
    %CncfDashboardApi.PipelineJobs{
      name: "App-Deploy",
      status: "running",
      ref: "ci_master",
      cloud_id: cloud.id,
    }
  end
  def k8_pipeline_job_factory do
    first_cloud = CncfDashboardApi.Repo.all(CncfDashboardApi.Clouds) |> List.first
    if first_cloud do
      cloud = first_cloud
    else
      cloud = insert(:cloud)
    end
    %CncfDashboardApi.PipelineJobs{
      name: "Kubernetes-Provisioning",
      status: "running",
      ref: "ci_master",
      cloud_id: cloud.id,
    }
	end
  def build_pipeline_factory do
    %CncfDashboardApi.Pipelines{
      ref: "ci_master",
      status: "success",
      sha: "2342342342343243sdfsdfsdfs",
      release_type: "build",
      pipeline_jobs: [build(:pipeline_job)],
    }

	end
  def cross_cloud_pipeline_factory do
    %CncfDashboardApi.Pipelines{
      ref: "ci_master",
      status: "success",
      sha: "2342342342343243sdfsdfsdfs",
      release_type: "deploy",
      pipeline_jobs: [build(:e2e_pipeline_job), build(:app_deploy_pipeline_job)],
    }

	end
  def cross_project_pipeline_factory do
    %CncfDashboardApi.Pipelines{
      ref: "ci_master",
      status: "success",
      sha: "2342342342343243sdfsdfsdfs",
      release_type: "deploy",
      pipeline_jobs: [build(:k8_pipeline_job)],
    }

	end

  def cross_cloud_source_key_project_monitor_factory do
    # use a real source key project id 
    projects = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == "cross-cloud" end)
    working_project = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == "coredns" end)
    # use a real pipeline id 
    pipelines = GitLabProxy.get_gitlab_pipelines(projects["id"]) |> List.first
    build_pipelines = GitLabProxy.get_gitlab_pipelines(working_project["id"]) |> List.first
    %CncfDashboardApi.SourceKeyProjectMonitor{
      # source_project_id: "1",
      source_project_id: projects["id"] |> Integer.to_string,
      # source_pipeline_id: "1",
      source_pipeline_id: pipelines["id"] |> Integer.to_string,
      source_pipeline_job_id: "1",
      pipeline_release_type: "head",
      active: true, 
      cloud: "aws",
      child_pipeline: true,
      target_project_name: "coredns",
      project_build_pipeline_id: build_pipelines["id"] |> Integer.to_string,
    }
  end

  def cross_project_source_key_project_monitor_factory do
    # use a real source key project id 
    projects = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == "cross-project" end)
    working_project = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == "coredns" end)
    # use a real pipeline id 
    pipelines = GitLabProxy.get_gitlab_pipelines(projects["id"]) |> List.first
    build_pipelines = GitLabProxy.get_gitlab_pipelines(working_project["id"]) |> List.first
    %CncfDashboardApi.SourceKeyProjectMonitor{
      # source_project_id: "1",
      source_project_id: projects["id"] |> Integer.to_string,
      # source_pipeline_id: "1",
      source_pipeline_id: pipelines["id"] |> Integer.to_string,
      source_pipeline_job_id: "1",
      pipeline_release_type: "head",
      active: true, 
      cloud: "aws",
      child_pipeline: true,
      target_project_name: "coredns",
      project_build_pipeline_id: build_pipelines["id"] |> Integer.to_string,
    }
  end

  def project_factory do
    %CncfDashboardApi.Projects{
      name: "Kubernetes",
      ssh_url_to_repo: "http://kubernetes.io/",
      http_url_to_repo: "http://kubernetes.io/",
      active: true,
      logo_url: "https://www.cncf.io/wp-content/uploads/2016/09/ico_kubernetes-100x100.png",
      web_url: "https://gitlab.dev.cncf.ci/coredns/coredns",
      display_name: "Kubernetes",
      sub_title: "Kub",
      yml_name: "Kubernetes",
      yml_gitlab_name: "kubernetes",
      project_url: "http://kubernetes.io/",
      repository_url: "https://gitlab.dev.cncf.ci/prometheus/prometheus",
      timeout: 900,
      order: 1,
      pipelines: [build(:pipeline)],
      ref_monitors: [build(:ref_monitor)],
    }
	end

  def source_key_project_monitor_factory do
    first_active_project =CncfDashboardApi.YmlReader.GitlabCi.project_list |> Enum.find(fn(x) -> x["active"] == true end)
    projects = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == first_active_project["yml_name"] end)
    # use a real pipeline id 
    pipelines = GitLabProxy.get_gitlab_pipelines(projects["id"]) |> List.first
    %CncfDashboardApi.SourceKeyProjectMonitor{
      # source_project_id: "1",
      source_project_id: projects["id"] |> Integer.to_string,
      # source_pipeline_id: "1",
      source_pipeline_id: pipelines["id"] |> Integer.to_string,
      source_pipeline_job_id: "1",
      pipeline_release_type: "stable",
      active: true, 
    }
  end

  def head_source_key_project_monitor_factory do
    # use a real source key project id 
    first_active_project =CncfDashboardApi.YmlReader.GitlabCi.project_list |> Enum.find(fn(x) -> x["active"] == true end)
    projects = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == first_active_project["yml_name"] end)
    # use a real pipeline id 
    pipelines = GitLabProxy.get_gitlab_pipelines(projects["id"]) |> List.first
    %CncfDashboardApi.SourceKeyProjectMonitor{
      # source_project_id: "1",
      source_project_id: projects["id"] |> Integer.to_string,
      # source_pipeline_id: "1",
      source_pipeline_id: pipelines["id"] |> Integer.to_string,
      source_pipeline_job_id: "1",
      pipeline_release_type: "head",
      active: true, 
    }
  end

  def source_key_pipeline_job_factory do
    %CncfDashboardApi.SourceKeyPipelineJobs{
      source_id: "1",
      new_id: 1,
    }
  end

  def source_key_project_factory do
    # use a real source key project id 
    first_active_project =CncfDashboardApi.YmlReader.GitlabCi.project_list |> Enum.find(fn(x) -> x["active"] == true end)
    projects = GitLabProxy.get_gitlab_projects |> Enum.find(fn(x) -> x["name"] == first_active_project["yml_name"] end)
    %CncfDashboardApi.SourceKeyProjects{
      # source_id: "1",
      source_id: projects["id"] |> Integer.to_string,
      new_id: 1,
    }
  end

  def pipeline_monitor_factory do
    %CncfDashboardApi.PipelineMonitor{
      project_id: 1,
      pipeline_id: 1,
      running: true,
      release_type: "stable",
      pipeline_type: "build"
    }
  end

  def build_pipeline_monitor_factory do
    %CncfDashboardApi.PipelineMonitor{
      project_id: 1,
      pipeline_id: 1,
      running: true,
      release_type: "stable",
      pipeline_type: "build"
    }
  end

  def cross_cloud_pipeline_monitor_factory do
    %CncfDashboardApi.PipelineMonitor{
      project_id: 1,
      pipeline_id: 1,
      running: true,
      release_type: "stable",
      pipeline_type: "deploy"
    }
  end

  def cross_project_pipeline_monitor_factory do
    %CncfDashboardApi.PipelineMonitor{
      project_id: 1,
      pipeline_id: 1,
      running: true,
      release_type: "stable",
      pipeline_type: "deploy"
    }
  end


end
