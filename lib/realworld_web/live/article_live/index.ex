defmodule RealworldWeb.ArticleLive.Index do
  use RealworldWeb, :live_view

  import RealworldWeb.ArticleLive.Actions, only: [actions: 1]

  alias Ash.Query
  alias Realworld.{Articles, Profiles}
  alias Realworld.Articles.Comment
  alias Realworld.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)

    if connected?(socket) do
      RealworldWeb.Endpoint.subscribe("comment:created:#{socket.assigns.article.id}")
      RealworldWeb.Endpoint.subscribe("comment:destroyed:#{socket.assigns.article.id}")
    end

    {:noreply, socket}
  end

  defp apply_action(socket, :index, %{"slug" => slug}) do
    case get_article_by_slug(slug, socket.assigns.current_user) do
      {:ok, article} ->
        socket
        |> assign(:article, article)
        |> assign(:is_owner, is_owner?(socket.assigns[:current_user], article.user))
        |> assign(:following, follows(socket.assigns[:current_user], article.user))
        |> assign(:favorite, favorited(article))

      _ ->
        redirect(socket, to: ~p"/")
    end
  end

  @impl true
  def handle_event("delete-article", _params, socket) do
    Articles.destroy_article!(socket.assigns.article, actor: socket.assigns.current_user)

    {:noreply, redirect(socket, to: ~p"/")}
  end

  def handle_event(
        "favorite-article",
        _,
        %{assigns: %{article: article}} = socket
      ) do
    case Articles.favorite(article.id, actor: socket.assigns.current_user) do
      {:ok, favorite} ->
        article = Map.put(article, :favorites_count, article.favorites_count + 1)

        socket =
          socket
          |> assign(:article, article)
          |> assign(:favorite, favorite)

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "unfavorite-article",
        _,
        %{assigns: %{current_user: current_user, article: article}} = socket
      ) do
    case Articles.unfavorite(article.id, return_destroyed?: true, actor: current_user) do
      {:ok, _} ->
        article = Map.put(article, :favorites_count, article.favorites_count - 1)

        socket =
          socket
          |> assign(:article, article)
          |> assign(:favorite, nil)

        {:noreply, socket}

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

  def handle_event(
        "follow-profile",
        _,
        %{assigns: %{current_user: current_user, article: %{user: user}}} = socket
      ) do
    case Profiles.follow(user.id, actor: current_user) do
      {:ok, follow} ->
        {:noreply, assign(socket, following: follow)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "unfollow-profile",
        _,
        %{assigns: %{current_user: current_user, article: article}} = socket
      ) do
    case Profiles.unfollow(article.user_id, return_destroyed?: true, actor: current_user) do
      {:ok, _} ->
        {:noreply, assign(socket, following: nil)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("follow-profile", _, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("unfollow-profile", _, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  @impl true
  def handle_info(
        %{topic: "comment:created:" <> _, event: "create", payload: %{data: comment}},
        socket
      ) do
    socket =
      update(socket, :article, fn article ->
        Map.put(article, :comments, article.comments ++ [comment])
      end)

    {:noreply, socket}
  end

  def handle_info(
        %{
          topic: "comment:destroyed:" <> _,
          event: "destroy",
          payload: %{data: comment}
        },
        socket
      ) do
    socket =
      update(socket, :article, fn article ->
        comments = Enum.reject(article.comments, fn c -> c.id == comment.id end)
        Map.put(article, :comments, comments)
      end)

    {:noreply, socket}
  end

  defp get_article_by_slug(slug, current_user) do
    comment_user_query = User |> Query.select([:username, :image, :created_at])

    comments_query =
      Comment |> Query.sort(created_at: :asc) |> Query.load(user: comment_user_query)

    slug
    |> Articles.get_article_by_slug(
      actor: current_user,
      load: [:user, :tags, :favorites_count, comments: comments_query]
    )
  end

  defp is_owner?(nil, _), do: false

  defp is_owner?(current_user, user), do: current_user.id == user.id

  defp follows(_current_user = nil, _user), do: nil

  defp follows(current_user, user) do
    case Profiles.following(user.id, actor: current_user) do
      {:ok, follow} -> follow
      _ -> nil
    end
  end

  def favorited(nil, _), do: nil

  def favorited(article) do
    case Articles.favorited(article.id) do
      {:ok, favorite} -> favorite
      _ -> nil
    end
  end
end
