defmodule CncfDashboardApi.CloudsTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Clouds

  @valid_attrs %{cloud_name: "some content", order: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Clouds.changeset(%Clouds{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Clouds.changeset(%Clouds{}, @invalid_attrs)
    refute changeset.valid?
  end
end
