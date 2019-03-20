require Logger;
require IEx;
defmodule CncfDashboardApi.GitlabMonitor.Job do 
  import Ecto.Query
  alias CncfDashboardApi.Repo
  use EctoConditionals, repo: Repo

 @doc """
  Gets a job names in order of precedence for a specific project based on `project_name`.

  Precendence is from least to most important 

  Returns `["job_name1", "job_name2"]`
  """
  def monitored_job_list(project_name) do
    cloud_list = CncfDashboardApi.YmlReader.GitlabCi.gitlab_pipeline_config()
    pipeline_config = Enum.find(cloud_list, fn(x) -> x["pipeline_name"] == project_name end) 
    pipeline_config["status_jobs"]
  end

  @doc """
  Gets a list of migrated jobs based on based on `pipeline_id` and `job_names`.

  job_names is a list of strings denoting the job name

  A migration from gitlab must have occured before calling this function in order to get 
  valid jobs 

  Returns `[%job1, %job2]`
  """
  def monitored_jobs(job_names, pipeline_id) do
    Logger.info fn ->
      "monitored_jobs job_names: #{inspect(job_names)}"
    end
    # get all the jobs for the internal pipeline
    jobs = Repo.all(from pj in CncfDashboardApi.PipelineJobs, 
                    where: pj.pipeline_id == ^pipeline_id,
                    where: pj.name in ^job_names)
    Logger.info fn ->
      "monitored_jobs: #{inspect(jobs)}"
    end

    # sort by job_names
    job_names
    |> Enum.reduce([], fn(job_name, acc) ->
      job = Enum.find(jobs, fn(x) -> x.name =~ job_name end) 
        if job do
          [job | acc]
        else
          acc
        end
    end)
    |> Enum.reverse
  end

 @doc """
  Gets the status and job based on precendence based on `monitored_jobs` and `child_pipeline`  

  If any job in the status jobs list has a status of failed, return failed
  else if any job in the list has a status of running, return running
  else 
     if not child pipeline
       if all jobs are a success, return success

  Returns :nojob if no job found

  Returns `%{:status => "success", :job => %PipelineJob}`
  """
  def status_job(monitored_jobs, child_pipeline) do
    # Logger.info fn ->
    #   "status_job monitored_jobs: #{inspect(monitored_jobs)}"
    # end
    # loop through the jobs list in the order of precedence
    # monitor_job_list e.g. ["e2e", "App-Deploy"]
    # create status string e.g. "failure"
    # If any job in the status jobs list has a status of failed, return failed
    # else if any job in the list has a status of running, return running
    # else 
    #    if not child pipeline
    #      if all jobs are a success, return success
    status_job = monitored_jobs 
             |> Enum.reduce_while(%{:status => "initial", :job => :nojob}, fn(job, acc) ->
               # Logger.info fn ->
               #   "monitored job: #{inspect(job)}"
               # end
                cond do
                  job && (job.status =~ "failed" || job.status =~ "canceled") ->
                    acc = %{status: "failed", job: job}
                    {:halt, acc}
                  job && (job.status =~ "running" || job.status =~ "created") ->
                    # can only go to a running status from initial, running, or success status
                    if (acc.status =~ "running" || acc.status =~ "initial" || acc.status =~ "success") do
                      acc = %{status: "running" , job: job}
                    end
                    {:cont, acc}
                  job && job.status =~ "success" ->
                    # The Backend Dashboard will NOT set the badge status to success when a 
                    # child -- it's ignored for a child 
                    # can only go to a success status from initial, running, or success status
                    if (child_pipeline == false && (acc.status =~ "success" || acc.status =~ "initial")) do
                      acc = %{status: "success", job: job} 
                    end
                    {:cont, acc}
                  true ->
                    Logger.error fn ->
                      "unhandled job status: #{inspect(job)}  not handled"
                    end
                    acc = %{status: "N/A", job: job} 
                    {:cont, acc}
                end 
             end) 
  end 


  def badge_status_by_pipeline_id(monitor_job_list, child_pipeline, _cloud, internal_pipeline_id) do
    Logger.info fn ->
      "badge_status_by_pipeline_id monitor_job_list, chid_pipeline, internal_pipeline_id: #{inspect(monitor_job_list)}, #{inspect(child_pipeline)}, #{inspect(internal_pipeline_id)}"
    end

    %{:status => status, :job => _} = CncfDashboardApi.GitlabMonitor.Job.monitored_jobs(monitor_job_list, internal_pipeline_id)
                  |> CncfDashboardApi.GitlabMonitor.Job.status_job(child_pipeline)
     status
  end

  def badge_url(monitor_job_list, child_pipeline, internal_pipeline_id) do
    Logger.info fn ->
      "badge url monitor_job_list, chid_pipeline, internal_pipeline_id: #{inspect(monitor_job_list)}, #{inspect(child_pipeline)}, #{inspect(internal_pipeline_id)}"
    end
     project = Repo.all(from projects in CncfDashboardApi.Projects, 
                                          left_join: pipelines in assoc(projects, :pipelines),     
                                          where: pipelines.id == ^internal_pipeline_id) 
                                          |> List.first
    Logger.info fn ->
      "badge url project: #{inspect(project)}"
    end

    status_job = CncfDashboardApi.GitlabMonitor.Job.monitored_jobs(monitor_job_list, internal_pipeline_id)
                  |> CncfDashboardApi.GitlabMonitor.Job.status_job(child_pipeline)

    Logger.info fn ->
      "status_job: #{inspect(status_job)}"
    end
    Logger.info fn ->
      "status_job.job: #{inspect(status_job.job)}"
    end

    if status_job.job != :nojob do
      Logger.info fn ->
        "status_job.job != :nojob"
      end
      source_key_pipeline_jobs = Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelineJobs)
      Logger.info fn ->
        "All source key pipeline jobs #{inspect(source_key_pipeline_jobs)}"
      end
      source_key_pipeline_jobs = Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelineJobs, where: skpj.new_id == ^status_job.job.id) |> List.first
      if source_key_pipeline_jobs do
        "#{project.web_url}/-/jobs/#{source_key_pipeline_jobs.source_id}"
      else
        ""
      end
    end
  end
end
