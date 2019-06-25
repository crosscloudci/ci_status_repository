defmodule CncfDashboardApi.DashboardChannel do
  use CncfDashboardApi.Web, :channel
  use EctoConditionals, repo: CncfDashboardApi.Repo

  alias CncfDashboardApi.Dashboard

  def join("dashboard:*", payload, socket) do
    response = CncfDashboardApi.GitlabMonitor.Dashboard.dashboard_response()
      {:ok, %{reply: response}, socket}

  end

  def join(topic, _resource, socket) do
    # if permitted_topic?(socket, :listen, topic) do
      { :ok, %{ message: "Joined" }, socket }
    # else
    #   { :error, :authentication_required }
    # end
  end

  # def join(_room, _payload, _socket) do
  #   { :error, :authentication_required }
  # end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (dashboard:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
