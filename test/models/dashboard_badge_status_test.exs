defmodule CncfDashboardApi.DashboardBadgeStatusTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.DashboardBadgeStatus

  @valid_attrs %{cloud_id: 42, order: 42, ref_monitor_id: 42, status: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = DashboardBadgeStatus.changeset(%DashboardBadgeStatus{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = DashboardBadgeStatus.changeset(%DashboardBadgeStatus{}, @invalid_attrs)
    refute changeset.valid?
  end
end
