defmodule CncfDashboardApi.SourceKeyProjectMonitorTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.SourceKeyProjectMonitor

  @valid_attrs %{source_pipeline_id: "some content", source_project_id: "some content", pipeline_release_type: "some content", active: true}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = SourceKeyProjectMonitor.changeset(%SourceKeyProjectMonitor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = SourceKeyProjectMonitor.changeset(%SourceKeyProjectMonitor{}, @invalid_attrs)
    refute changeset.valid?
  end
end
