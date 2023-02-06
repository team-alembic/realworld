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
      Form.for_create(User, :register_with_password, api: Accounts)
    )
  end

  # def handle_event("validate", %{"user" => user_params}, socket) do
  #   changeset = Accounts.change_user_registration(%User{}, user_params)
  #   {:noreply, assign(socket, changeset: changeset)}
  # end

  # def handle_event("save", %{"user" => user_params}, socket) do
  #   case Accounts.register_user(user_params) do
  #     {:ok, user} ->
  #       changeset = Accounts.change_user_registration(user)
  #       {:noreply, assign(socket, changeset: changeset)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, :changeset, changeset)}
  #   end
  # end
end
