defmodule CncfDashboardApi.CloudJobStatusTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.CloudJobStatus

  @valid_attrs %{cloud_id: 42, pipeline_id: 42, status: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = CloudJobStatus.changeset(%CloudJobStatus{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = CloudJobStatus.changeset(%CloudJobStatus{}, @invalid_attrs)
    refute changeset.valid?
  end
end
