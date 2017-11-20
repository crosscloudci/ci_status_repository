defmodule CncfDashboardApi.DashboardTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Dashboard

  @valid_attrs %{last_check: Ecto.DateTime.utc, gitlab_ci_yml: "some content"}
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
