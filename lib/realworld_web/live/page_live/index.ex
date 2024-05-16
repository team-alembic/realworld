defmodule RealworldWeb.PageLive.Index do
  use RealworldWeb, :live_view
  alias Realworld.Articles

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_offset, 0)
      |> assign(:page_limit, 20)
      |> assign(:filter_tag, nil)
      |> assign(:articles, [])
      |> assign(:tags, [])
      |> assign(:pages, 0)
      |> assign(:active_page, 1)
      |> assign(:active_view, :global_feed)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> maybe_assign(:filter_tag, params["tag"])
      |> maybe_assign(:active_view, active_view(params["tag"]))
      |> maybe_assign(:active_page, page(params["page"]))
      |> maybe_assign(:page_offset, page_offset(page(params["page"]), socket.assigns.page_limit))

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    with {:ok, page} <- list_articles(socket),
         {:ok, tags} <- Realworld.Articles.Tag |> Realworld.Articles.read() do
      socket
      |> assign(:articles, page.results)
      |> assign(:pages, ceil(page.count / socket.assigns.page_limit))
      |> assign(:tags, tags)
    else
      _err ->
        put_flash(socket, :error, "Unable to fetch articles/tags. Please try again later.")
    end
  end

  defp list_articles(%{assigns: %{current_user: current_user, active_view: active_view}} = socket) do
    Articles.list_articles(
      %{filter: construct_filter(socket.assigns), private_feed?: active_view == :private_feed},
      page: [limit: socket.assigns.page_limit, offset: socket.assigns.page_offset],
      actor: current_user
    )
  end

  defp active_view(nil), do: nil
  defp active_view(_), do: :tag_feed

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

  defp construct_filter(assigns) do
    Map.new()
    |> maybe_put(:tag, assigns.filter_tag)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)

  def active_class(on_page, active_page) when on_page == active_page, do: "active"
  def active_class(_on_page, _active_page), do: ""

  @impl true
  def handle_event("global-feed", _params, socket) do
    socket =
      socket
      |> assign(:filter_tag, nil)
      |> assign(:active_view, :global_feed)
      |> assign(:active_page, 1)
      |> assign(:page_offset, 0)

    {:noreply, push_patch(socket, to: "/")}
  end

  @impl true
  def handle_event("private-feed", _params, socket) do
    socket =
      socket
      |> assign(:filter_tag, nil)
      |> assign(:active_view, :private_feed)
      |> assign(:active_page, 1)
      |> assign(:page_offset, 0)

    {:noreply, push_patch(socket, to: "/")}
  end

  def handle_event(
        "favorite-article",
        %{"article_id" => article_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    case Articles.favorite(article_id, actor: current_user) do
      {:ok, %{inserted_at: inserted_at, updated_at: inserted_at}} ->
        {:noreply, socket}

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
    with {:ok, _} <-
           Articles.unfavorite(article_id, actor: current_user, return_destroyed?: true) do
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
end
