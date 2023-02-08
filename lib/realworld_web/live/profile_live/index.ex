defmodule RealworldWeb.ProfileLive.Index do
  use RealworldWeb, :live_view
  alias Realworld.Accounts

  @impl true
  def mount(_params, %{"user" => "user?id=" <> user_id}, socket) do
    {:ok, assign(socket, current_user_id: user_id)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("edit-profile", _, socket) do
    {:noreply, redirect(socket, to: Routes.settings_index_path(socket, :index))}
  end

  defp apply_action(socket, :profile, %{"username" => username}) do
    case Accounts.User.get_by_username(username) do
      {:ok, user} ->
        socket
        |> assign(:profile_user, user)

      _ ->
        redirect(socket, to: Routes.page_index_path(socket, :index))
    end
  end

  defp default_image(nil), do: "https://api.realworld.io/images/smiley-cyrus.jpeg"
  defp default_image(image), do: image
end
