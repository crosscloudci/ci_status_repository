defmodule CncfDashboardApi.PipelineJobsTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.PipelineJobs

  @valid_attrs %{name: "some content", ref: "some content", status: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PipelineJobs.changeset(%PipelineJobs{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PipelineJobs.changeset(%PipelineJobs{}, @invalid_attrs)
    refute changeset.valid?
  end
end
