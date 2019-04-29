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
               Logger.info fn ->
                 "monitored job: #{inspect(job)}"
               end
                {continue, acc} = badge_job_status({job.status, acc, child_pipeline, job})
                # cond do
                #   job && (job.status =~ "failed" || job.status =~ "canceled") ->
                #     acc = %{status: "failed", job: job}
                #     {:halt, acc}
                #   job && (job.status =~ "running" || job.status =~ "created") ->
                #     # can only go to a running status from initial, running, or success status
                #     if (acc.status =~ "running" || acc.status =~ "initial" || acc.status =~ "success") do
                #       acc = %{status: "running" , job: job}
                #     end
                #     {:cont, acc}
                #   job && job.status =~ "success" ->
                #     # The Backend Dashboard will NOT set the badge status to success when a 
                #     # child -- it's ignored for a child 
                #     # can only go to a success status from initial, running, or success status
                #     if (child_pipeline == false && (acc.status =~ "success" || acc.status =~ "initial")) do
                #       acc = %{status: "success", job: job} 
                #     end
                #     {:cont, acc}
                #   true ->
                #     Logger.error fn ->
                #       "unhandled job status: #{inspect(job)}  not handled"
                #     end
                #     acc = %{status: "N/A", job: job} 
                #     {:cont, acc}
                # end 
             end) 
        Logger.info fn ->
          "status job: #{inspect(status_job)}"
        end
        # # ticket #230
        if status_job.status == "initial" do
          # status_job.status = "N/A"
          status_job = %{status_job | job: status_job.job, status: "N/A"}
        end
        status_job
  end 

  # Stay running if previous status (in order of precendent) was running
  def precendent_before_running_status({"running", acc, job}) do
    Logger.info fn ->
      "precendent_before_running_status #{inspect({"running", acc, job})}"
    end
    acc = %{status: "running" , job: job}
    {:cont, acc}
  end

  # Allow change to running if previous status (in order of precendent) was initial 
  def precendent_before_running_status({"initial", acc, job}) do
    Logger.info fn ->
      "precendent_before_running_status #{inspect({"initial", acc, job})}"
    end
    precendent_before_running_status({"running", acc, job})
  end

  # Allow change to running if previous status (in order of precendent) was success 
  def precendent_before_running_status({"success", acc, job}) do
    Logger.info fn ->
      "precendent_before_running_status #{inspect({"success", acc, job})}"
    end
    precendent_before_running_status({"running", acc, job})
  end

  # Stay running if previous status (in order of precendent) was not Running/Initial/Success 
  def precendent_before_running_status({status, acc, job}) do
    Logger.info fn ->
      "precendent_before_running_status #{inspect({status, acc, job})}"
    end
    {:cont, acc}
  end

  # The Backend Dashboard will NOT set the badge status to success when a 
  # child -- it's ignored for a child 
  # Allow change to a success status from if previous status (in order of precendent) is success
  # and child pipeline is false 
  def precendent_before_success_status({"success", acc, false, job}) do
    Logger.info fn ->
      "precendent_before_success_status #{inspect({"success", acc, false, job})}"
    end
    acc = %{status: "success", job: job} 
    {:cont, acc}
  end

  # Allow change to success if previous status (in order of precendent) was initial 
  def precendent_before_success_status({"initial", acc, child_pipline, job}) do
    Logger.info fn ->
      "precendent_before_success_status #{inspect({"initial", acc, child_pipline, job})}"
    end
    acc = %{status: "success", job: job} 
    {:cont, acc}
  end

  # Stay same status if previous status (in order of precendent) was not initial or (success
  # and child pipeline is false)
  def precendent_before_success_status({status, acc, child_pipline, job}) do
    Logger.info fn ->
      "precendent_before_success_status #{inspect({status, acc, child_pipline, job})}"
    end
    {:cont, acc}
  end

  # Initial status
  def badge_job_status({:nojob, acc, child_pipline, job}) do
    Logger.info fn ->
      "badge_job_status #{inspect({:nojob, acc, child_pipline, job})}"
    end
    acc = %{status: "N/A", job: job} 
    {:cont, acc}
  end

  # Set a status to failed the first time we see it (in order of precendent)
  def badge_job_status({"failed", acc, _, job}) do
    Logger.info fn ->
      "badge_job_status #{inspect({"failed", acc, :nothing, job})}"
    end
    acc = %{status: "failed", job: job}
    {:halt, acc}
  end

  # Set a status to failed the first time we see canceled (in order of precendent)
  def badge_job_status({"canceled", acc, child_pipeline, job}) do
    Logger.info fn ->
      "badge_job_status #{inspect({"canceled", acc, child_pipeline, job})}"
    end
    badge_job_status({"failed", acc, child_pipeline, job})
  end

  # Check precendent before a running status to see if change is allowed
  def badge_job_status({"running", acc, _, job}) do
    Logger.info fn ->
      "badge_job_status running #{inspect({"running", acc, :nothing, job})}"
    end
    precendent_before_running_status({acc.status, acc, job})
  end

  # Change status to running
  # Check precendent before a created status to see if change is allowed
  def badge_job_status({"created", acc, child_pipeline, job}) do
    Logger.info fn ->
      "badge_job_status #{inspect({"created", acc, child_pipeline, job})}"
    end
    badge_job_status({"running", acc, child_pipeline, job})
  end

  # We should never see a skipped badge while order of precendent is in different stages 
  # e.g. compile: skipped, container: running 
  # TODO handle multiple jobs in the same stage
  def badge_job_status({"skipped", acc, _, job}) do
    Logger.info fn ->
      "skipped job, using prevous job for status and url: #{inspect({"skipped", acc, :nothing, job})}"
    end
    # Ignore skipped status by keeping previous status and 
    # keep going down the list of monitored jobs in the order of precendent
    if acc.job == :nojob do
      acc = %{status: acc.status, job: acc.job}
    else
      acc = %{status: acc.job.status, job: acc.job}
    end
    {:cont, acc}
  end

  # Check precendent before a success status to see if change is allowed
  def badge_job_status({"success", acc, child_pipeline, job}) do
    Logger.info fn ->
      "badge_job_status success #{inspect({"success", acc, child_pipeline, job})}"
    end
    precendent_before_success_status({acc.status, acc, child_pipeline, job})
  end

  def badge_job_status({status, acc, child_pipline, job}) do
    Logger.error fn ->
      "unhandled job status: #{inspect({status, acc, child_pipline, job})} not handled"
    end
    acc = %{status: "N/A", job: job} 
    {:cont, acc}
  end

  def badge_status_by_pipeline_id(monitor_job_list, child_pipeline, _cloud, internal_pipeline_id) do
    Logger.info fn ->
      "badge_status_by_pipeline_id monitor_job_list, child_pipeline, internal_pipeline_id: #{inspect(monitor_job_list)}, #{inspect(child_pipeline)}, #{inspect(internal_pipeline_id)}"
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
      # Logger.info fn ->
      #   "All source key pipeline jobs #{inspect(source_key_pipeline_jobs)}"
      # end
      source_key_pipeline_jobs = Repo.all(from skpj in CncfDashboardApi.SourceKeyPipelineJobs, where: skpj.new_id == ^status_job.job.id) |> List.first
      if source_key_pipeline_jobs do
        "#{project.web_url}/-/jobs/#{source_key_pipeline_jobs.source_id}"
      else
        ""
      end
    end
  end
end
