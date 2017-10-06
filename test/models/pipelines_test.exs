defmodule CncfDashboardApi.PipelinesTest do
  use CncfDashboardApi.ModelCase

  alias CncfDashboardApi.Pipelines

  @valid_attrs %{ref: "some content", status: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Pipelines.changeset(%Pipelines{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Pipelines.changeset(%Pipelines{}, @invalid_attrs)
    refute changeset.valid?
  end
end
