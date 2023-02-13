defmodule RealworldWeb.ProfileLive.Index do
  use RealworldWeb, :live_view
  alias Realworld.Accounts
  alias Realworld.Profiles

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign_defaults(session, socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("edit-profile", _, socket) do
    {:noreply, redirect(socket, to: Routes.settings_index_path(socket, :index))}
  end

  def handle_event("follow-profile", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, redirect(socket, to: Routes.auth_path(socket, {:user, :password, :sign_in}))}
  end

  def handle_event("unfollow-profile", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, redirect(socket, to: Routes.auth_path(socket, {:user, :password, :sign_in}))}
  end

  def handle_event(
        "follow-profile",
        _,
        %{assigns: %{current_user: current_user, profile_user: profile_user}} = socket
      ) do
    case Profiles.Follow.create_following(current_user.id, profile_user.id) do
      {:ok, follow} ->
        {:noreply, assign(socket, following: follow)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "unfollow-profile",
        _,
        %{assigns: %{following: following}} = socket
      ) do
    case Profiles.destroy(following) do
      :ok ->
        {:noreply, assign(socket, following: nil)}

      _ ->
        {:noreply, socket}
    end
  end

  defp apply_action(socket, :profile, %{"username" => username}) do
    case Accounts.User.get_by_username(username) do
      {:ok, user} ->
        socket
        |> assign(:profile_user, user)
        |> assign(:following, is_following?(socket.assigns.current_user, user))

      _ ->
        redirect(socket, to: Routes.page_index_path(socket, :index))
    end
  end

  defp is_following?(_current_user = nil, _profile_user), do: false

  defp is_following?(current_user, profile_user) do
    case Profiles.Follow.following?(current_user.id, profile_user.id) do
      {:ok, follow} ->
        follow

      _ ->
        nil
    end
  end

  defp default_image(nil), do: "https://api.realworld.io/images/smiley-cyrus.jpeg"
  defp default_image(image), do: image
end
