defmodule CncfDashboardApi.SourceKeyPipelinesTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.SourceKeyPipelines

  @valid_attrs %{new_id: 42, source_id: "some content", source_name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = SourceKeyPipelines.changeset(%SourceKeyPipelines{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = SourceKeyPipelines.changeset(%SourceKeyPipelines{}, @invalid_attrs)
    refute changeset.valid?
  end
end
