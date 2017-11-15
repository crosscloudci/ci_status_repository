defmodule CncfDashboardApi.RefMonitorTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.RefMonitor

  @valid_attrs %{order: 42, pipeline_id: 42, project_id: 42, ref: "some content", release_type: "some content", sha: "some content", status: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = RefMonitor.changeset(%RefMonitor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = RefMonitor.changeset(%RefMonitor{}, @invalid_attrs)
    refute changeset.valid?
  end
end
