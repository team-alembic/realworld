defmodule RealworldWeb.ProfileLive.Index do
  use RealworldWeb, :live_view
  alias Realworld.Accounts
  alias Realworld.Articles.Article
  alias Realworld.Profiles

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      Ash.set_actor(socket.assigns[:current_user])
    end

    socket =
      socket
      |> assign(:page_offset, 0)
      |> assign(:page_limit, 20)
      |> assign(:articles, [])
      |> assign(:pages, 0)
      |> assign(:active_page, 1)
      |> assign(:active_view, :my_articles)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> maybe_assign(:active_page, page(params["page"]))
      |> maybe_assign(:page_offset, page_offset(page(params["page"]), socket.assigns.page_limit))

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("edit-profile", _, socket) do
    {:noreply, redirect(socket, to: Routes.settings_index_path(socket, :index))}
  end

  def handle_event("follow-profile", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, redirect(socket, to: Routes.auth_index_path(socket, :login))}
  end

  def handle_event("unfollow-profile", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, redirect(socket, to: Routes.auth_index_path(socket, :login))}
  end

  def handle_event(
        "follow-profile",
        _,
        %{assigns: %{current_user: _current_user, profile_user: profile_user}} = socket
      ) do
    case Profiles.Follow.create_following(profile_user.id) do
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

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :profile, %{
         "username" => username
       }) do
    with {:ok, user} <- Accounts.User.get_by_username(username),
         {:ok, page} <-
           Article.list_articles(
             construct_filter(socket.assigns.active_view, user),
             page: [limit: socket.assigns.page_limit, offset: socket.assigns.page_offset]
           ) do
      socket
      |> assign(:articles, page.results)
      |> assign(:pages, ceil(page.count / socket.assigns.page_limit))
      |> assign(:profile_user, user)
      |> assign(:following, following(current_user, user))
    else
      _err ->
        put_flash(socket, :error, "Unable to fetch articles. Please try again later.")
    end
  end

  defp apply_action(socket, :profile, %{"username" => username}) do
    with {:ok, user} <- Accounts.User.get_by_username(username),
         {:ok, page} <-
           Article.list_articles(
             construct_filter(socket.assigns.active_view, user),
             page: [limit: socket.assigns.page_limit, offset: socket.assigns.page_offset]
           ) do
      socket
      |> assign(:articles, page.results)
      |> assign(:pages, ceil(page.count / socket.assigns.page_limit))
      |> assign(:profile_user, user)
      |> assign(:following, nil)
      |> assign(:current_user, nil)
    else
      _ ->
        put_flash(socket, :error, "Unable to fetch articles. Please try again later.")
    end
  end

  defp following(_current_user = nil, _profile_user), do: false

  defp following(_current_user, profile_user) do
    case Profiles.Follow.following(profile_user.id) do
      {:ok, follow} ->
        follow

      _ ->
        nil
    end
  end

  defp default_image(nil), do: "https://api.realworld.io/images/smiley-cyrus.jpeg"
  defp default_image(image), do: image

  defp page(nil), do: nil

  defp page(page_param) do
    {active_page, _} = Integer.parse(page_param)
    active_page
  end

  defp page_offset(nil, _page_limit), do: nil

  defp page_offset(page_param, page_limit) do
    (page_param - 1) * page_limit
  end

  defp maybe_assign(socket, _key, nil), do: socket
  defp maybe_assign(socket, key, val), do: socket |> assign(key, val)

  defp construct_filter(:my_articles, profile_user) do
    Map.new(%{author: profile_user.id})
  end

  defp construct_filter(:my_favourite_articles, profile_user) do
    Map.new(%{favourited: profile_user.id})
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)

  def active_class(on_page, active_page) when on_page == active_page, do: "active"
  def active_class(_on_page, _active_page), do: ""

  @impl true
  def handle_event("my-articles", _params, socket) do
    socket =
      socket
      |> assign(:active_view, :my_articles)
      |> assign(:active_page, 1)
      |> assign(:page_offset, 0)

    {:noreply, push_patch(socket, to: "/profile/#{socket.assigns.profile_user.username}")}
  end

  @impl true
  def handle_event("my-favourite-articles", _params, socket) do
    socket =
      socket
      |> assign(:active_view, :my_favourite_articles)
      |> assign(:active_page, 1)
      |> assign(:page_offset, 0)

    {:noreply, push_patch(socket, to: "/profile/#{socket.assigns.profile_user.username}")}
  end
end
