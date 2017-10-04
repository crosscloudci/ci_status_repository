defmodule CncfDashboardApi.ProjectsTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Projects

  @valid_attrs %{http_url_to_repo: "some content", name: "some content", ssh_url_to_repo: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Projects.changeset(%Projects{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Projects.changeset(%Projects{}, @invalid_attrs)
    refute changeset.valid?
  end
end
