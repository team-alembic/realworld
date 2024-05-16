defmodule RealworldWeb.ProfileLive.Index do
  use RealworldWeb, :live_view
  alias Realworld.{Accounts, Articles, Profiles}

  @impl true
  def mount(_params, _session, socket) do
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
    {:noreply, redirect(socket, to: ~p"/settings")}
  end

  def handle_event("follow-profile", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("unfollow-profile", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event(
        "follow-profile",
        _,
        %{assigns: %{current_user: current_user, profile_user: profile_user}} = socket
      ) do
    case Profiles.follow(profile_user.id, actor: current_user) do
      {:ok, follow} ->
        {:noreply, assign(socket, following: follow)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "unfollow-profile",
        _,
        %{assigns: %{current_user: current_user, profile_user: profile_user}} = socket
      ) do
    case Profiles.unfollow(profile_user.id,
           return_destroyed?: true,
           actor: current_user
         ) do
      {:ok, _} ->
        {:noreply, assign(socket, following: nil)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("my-articles", _params, socket) do
    socket =
      socket
      |> assign(:active_view, :my_articles)
      |> assign(:active_page, 1)
      |> assign(:page_offset, 0)

    {:noreply, push_patch(socket, to: "/profile/#{socket.assigns.profile_user.username}")}
  end

  def handle_event("my-favourite-articles", _params, socket) do
    socket =
      socket
      |> assign(:active_view, :my_favourite_articles)
      |> assign(:active_page, 1)
      |> assign(:page_offset, 0)

    {:noreply, push_patch(socket, to: "/profile/#{socket.assigns.profile_user.username}")}
  end

  def handle_event(
        "favorite-article",
        %{"article_id" => article_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    case Articles.favorite(article_id, actor: current_user) do
      {:ok, _favorite} ->
        new_articles =
          socket.assigns.articles
          |> Enum.map(fn article ->
            if article.id === article_id do
              article
              |> Map.put(:favorites_count, article.favorites_count + 1)
              |> Map.put(:is_favorited, true)
            else
              article
            end
          end)

        socket =
          socket
          |> assign(:articles, new_articles)

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "unfavorite-article",
        %{"article_id" => article_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    with {:ok, _} <- Articles.unfavorite(article_id, actor: current_user, return_destroyed?: true) do
      new_articles =
        socket.assigns.articles
        |> Enum.map(fn article ->
          if article.id === article_id do
            article
            |> Map.put(:favorites_count, article.favorites_count - 1)
            |> Map.put(:is_favorited, false)
          else
            article
          end
        end)

      socket =
        socket
        |> assign(:articles, new_articles)

      {:noreply, socket}
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("favorite-article", _, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("unfavorite-article", _, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :profile, %{
         "username" => username
       }) do
    with {:ok, user} <- Accounts.get_user_by_username(username),
         {:ok, page} <-
           Articles.list_articles(
             %{filter: construct_filter(socket.assigns.active_view, user)},
             page: [limit: socket.assigns.page_limit, offset: socket.assigns.page_offset],
             actor: current_user
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
    with {:ok, user} <- Accounts.get_user_by_username(username),
         {:ok, page} <-
           Articles.list_articles(
             %{filter: construct_filter(socket.assigns.active_view, user)},
             page: [limit: socket.assigns.page_limit, offset: socket.assigns.page_offset],
             actor: socket.assigns.current_user
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

  defp following(current_user, profile_user) do
    case Profiles.following(profile_user.id, actor: current_user) do
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

  def active_class(on_page, active_page) when on_page == active_page, do: "active"
  def active_class(_on_page, _active_page), do: ""
end
