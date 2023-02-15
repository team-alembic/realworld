defmodule RealworldWeb.EditorLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Articles.Article

  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, article} = Article.get_by_slug(slug) |> Realworld.Articles.load(:tags)

    form =
      AshPhoenix.Form.for_update(article, :update,
        api: Realworld.Articles,
        actor: socket.assigns.current_user,
        forms: [
          auto?: true
        ]
      )

    {:ok, assign(socket, form: form)}
  end

  def mount(_params, _session, socket) do
    form =
      AshPhoenix.Form.for_create(Article, :publish,
        api: Realworld.Articles,
        actor: socket.assigns.current_user,
        forms: [
          auto?: true
        ]
      )

    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: false)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", _params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form) do
      {:ok, result} ->
        # Do something with the result, like redirect
        IO.inspect(result)
        {:noreply, redirect(socket, to: "/article/#{result.slug}")}

      {:error, form} ->
        IO.inspect(form)
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("add_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)
    tags = socket.assigns.form.forms[:tags] || []

    case Enum.any?(tags, fn t -> AshPhoenix.Form.value(t, :name) == tag end) do
      true ->
        {:reply, %{ tag_added: false }, socket}

      false ->
        form = AshPhoenix.Form.add_form(socket.assigns.form, "form[tags]", params: %{name: tag})
        {:reply, %{ tag_added: true }, assign(socket, form: form)}
    end
  end

  def handle_event("remove_tag", %{"path" => path}, socket) do
    form = AshPhoenix.Form.remove_form(socket.assigns.form, path)
    {:noreply, assign(socket, form: form)}
  end
end
