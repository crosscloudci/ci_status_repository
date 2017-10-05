defmodule CncfDashboardApi.SourceKeyProjectsTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.SourceKeyProjects

  @valid_attrs %{new_id: 42, source_id: "some content", source_name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = SourceKeyProjects.changeset(%SourceKeyProjects{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = SourceKeyProjects.changeset(%SourceKeyProjects{}, @invalid_attrs)
    refute changeset.valid?
  end
end
