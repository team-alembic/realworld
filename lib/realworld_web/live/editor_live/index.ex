defmodule RealworldWeb.EditorLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Articles
  alias Realworld.Articles.Article

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: false)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", _params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form) do
      {:ok, result} ->
        {:noreply, redirect(socket, to: "/article/#{result.slug}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("add_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)
    tags = socket.assigns.form.source.forms[:tags] || []

    case Enum.any?(tags, fn t -> AshPhoenix.Form.value(t, :name) == tag end) do
      true ->
        {:reply, %{tag_added: false}, socket}

      false ->
        form = AshPhoenix.Form.add_form(socket.assigns.form, "form[tags]", params: %{name: tag})
        {:reply, %{tag_added: true}, assign(socket, form: form)}
    end
  end

  def handle_event("remove_tag", %{"path" => path}, socket) do
    form = AshPhoenix.Form.remove_form(socket.assigns.form, path)
    {:noreply, assign(socket, form: form)}
  end

  defp apply_action(socket, :new, _) do
    form =
      AshPhoenix.Form.for_create(Article, :publish,
        api: Realworld.Articles,
        actor: socket.assigns.current_user,
        forms: [
          auto?: true
        ]
      )
      |> to_form

    assign(socket, form: form)
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    case get_article_by_slug(slug) do
      {:ok, article} ->
        form =
          AshPhoenix.Form.for_update(article, :update,
            actor: socket.assigns.current_user,
            forms: [
              auto?: true
            ]
          )
          |> to_form

        assign(socket, form: form)

      _ ->
        redirect(socket, to: ~p"/")
    end
  end

  defp get_article_by_slug(slug) do
    slug |> Articles.get_article_by_slug() |> Ash.load(:tags)
  end
end
