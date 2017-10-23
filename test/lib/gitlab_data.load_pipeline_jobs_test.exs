Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.GitlabData.LoadPipelineJobsTest do
  use ExUnit.Case, async: true
  use CncfDashboardApi.ModelCase

  # @tag timeout: 300_000 
  # describe "run/1" do
  #   test "Upserts all pipeline jobs" do
  #     Mix.Tasks.GitlabData.LoadPipelineJobs.run([])
  #
  #     assert_received {:mix_shell, :info, [upsert_count]}    # pattern matching FTW
  #
  #     assert upsert_count =~ "records upserted"
  #   end
  # end
end
