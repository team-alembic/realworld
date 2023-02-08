defmodule RealworldWeb.ProfileLive.Index do
  use RealworldWeb, :live_view

  @impl true
  def mount(%{"username" => _username}, _session, socket) do
    {:ok, socket}
  end
end
