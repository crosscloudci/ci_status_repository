defmodule CncfDashboardApi.PipelineMonitorTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.PipelineMonitor

  @valid_attrs %{pipeline_id: 42, pipeline_type: "some content", project_id: 42, release_type: "some content", running: true}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PipelineMonitor.changeset(%PipelineMonitor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PipelineMonitor.changeset(%PipelineMonitor{}, @invalid_attrs)
    refute changeset.valid?
  end
end
