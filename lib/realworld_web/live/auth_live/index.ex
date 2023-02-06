defmodule RealworldWeb.AuthLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Accounts
  alias Realworld.Accounts.User
  alias AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      :form,
      Form.for_create(User, :register_with_password, api: Accounts, as: "user")
    )
  end
end
