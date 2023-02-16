defmodule RealworldWeb.ArticleLive.Index do
  use RealworldWeb, :live_view

  import RealworldWeb.ArticleLive.Actions, only: [actions: 1]

  alias Realworld.Articles
  alias Realworld.Articles.Article

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      Ash.set_actor(socket.assigns[:current_user])
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # @impl true
  # def handle_event("validate", %{"form" => params}, socket) do
  #   form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: false)
  #   {:noreply, assign(socket, form: form)}
  # end

  # def handle_event("save", _params, socket) do
  #   case AshPhoenix.Form.submit(socket.assigns.form) do
  #     {:ok, result} ->
  #       # Do something with the result, like redirect
  #       IO.inspect(result)
  #       {:noreply, redirect(socket, to: "/article/#{result.slug}")}

  #     {:error, form} ->
  #       IO.inspect(form)
  #       {:noreply, assign(socket, form: form)}
  #   end
  # end

  # def handle_event("add_tag", %{"tag" => tag}, socket) do
  #   tag = String.trim(tag)
  #   tags = socket.assigns.form.forms[:tags] || []

  #   case Enum.any?(tags, fn t -> AshPhoenix.Form.value(t, :name) == tag end) do
  #     true ->
  #       {:reply, %{tag_added: false}, socket}

  #     false ->
  #       form = AshPhoenix.Form.add_form(socket.assigns.form, "form[tags]", params: %{name: tag})
  #       {:reply, %{tag_added: true}, assign(socket, form: form)}
  #   end
  # end

  # def handle_event("remove_tag", %{"path" => path}, socket) do
  #   form = AshPhoenix.Form.remove_form(socket.assigns.form, path)
  #   {:noreply, assign(socket, form: form)}
  # end

  defp apply_action(socket, :index, %{"slug" => slug}) do
    case get_article_by_slug(slug) do
      {:ok, article} ->
        assign(socket,
          article: article,
          author_profile_url: Routes.profile_index_path(socket, :profile, article.user.username),
          is_owner: is_owner?(socket.assigns[:current_user], article.user)
        )

      _ ->
        redirect(socket, to: Routes.page_index_path(socket, :index))
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    socket.assigns.article
    |> Ash.Changeset.for_destroy(:destroy)
    |> Articles.destroy()

    {:noreply, redirect(socket, to: Routes.page_index_path(socket, :index))}
  end

  def handle_event("favorite", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("follow", _params, socket) do
    {:noreply, socket}
  end

  defp get_article_by_slug(slug) do
    slug |> Article.get_by_slug() |> Realworld.Articles.load([:user, :tags])
  end

  defp is_owner?(nil, _), do: false
  defp is_owner?(current_user, user), do: current_user.id == user.id
end
