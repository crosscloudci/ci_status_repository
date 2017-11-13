defmodule CncfDashboardApi.BuildJobStatusTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.BuildJobStatus

  @valid_attrs %{pipeline_id: 42, pipeline_monitor_id: 42, status: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = BuildJobStatus.changeset(%BuildJobStatus{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = BuildJobStatus.changeset(%BuildJobStatus{}, @invalid_attrs)
    refute changeset.valid?
  end
end
