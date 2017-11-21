defmodule CncfDashboardApi.CloudsView do
  use CncfDashboardApi.Web, :view

  def render("index.json", %{clouds: clouds}) do
    %{data: render_many(clouds, CncfDashboardApi.CloudsView, "clouds.json")}
  end

  def render("show.json", %{clouds: clouds}) do
    %{data: render_one(clouds, CncfDashboardApi.CloudsView, "clouds.json")}
  end

  def render("clouds.json", %{clouds: clouds}) do
    %{id: clouds.id,
      cloud_id: clouds.id,
      order: clouds.order,
      cloud_name: clouds.display_name}
  end
end
