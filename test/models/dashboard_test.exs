defmodule CncfDashboardApi.DashboardTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Dashboard

  @valid_attrs %{last_check: %{day: 17, month: 4, year: 2010}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Dashboard.changeset(%Dashboard{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Dashboard.changeset(%Dashboard{}, @invalid_attrs)
    refute changeset.valid?
  end
end
