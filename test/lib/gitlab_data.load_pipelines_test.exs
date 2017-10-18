Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.GitlabData.LoadPipelinesTest do
  use ExUnit.Case, async: true
  use CncfDashboardApi.ModelCase

  describe "run/1" do
    test "Upserts all pipelines" do
      Mix.Tasks.GitlabData.LoadPipelines.run([])

      assert_received {:mix_shell, :info, [upsert_count]}    # pattern matching FTW

      assert upsert_count =~ "records upserted"
    end
  end
end
