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

  def handle_event("save", %{"form" => params}, socket) do
    # Tag pills are added server-side (the TagInput hook pushes "add_tag" →
    # add_form), so a submit racing that round-trip would be missing the
    # newest pill from its DOM params and silently drop the tag. The
    # server-side form is authoritative for tags; take everything else from
    # the submitted params.
    tags =
      (socket.assigns.form.source.forms[:tags] || [])
      |> Enum.map(&%{"name" => AshPhoenix.Form.value(&1, :name)})

    params = Map.put(params, "tags", tags)

    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, result} ->
        {:noreply, redirect(socket, to: ~p"/article/#{result.slug}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("add_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)
    tags = socket.assigns.form.source.forms[:tags] || []

    if tag == "" || Enum.any?(tags, fn t -> AshPhoenix.Form.value(t, :name) == tag end) do
      {:reply, %{tag_added: false}, socket}
    else
      # `validate_opts: [errors: false]` — add_form re-validates the whole
      # form by default, which would flash "is required" errors on fields
      # the user hasn't reached yet (same reason the "validate" event passes
      # `errors: false`).
      form =
        AshPhoenix.Form.add_form(socket.assigns.form, "form[tags]",
          params: %{name: tag},
          validate_opts: [errors: false]
        )

      {:reply, %{tag_added: true}, assign(socket, form: form)}
    end
  end

  def handle_event("remove_tag", %{"path" => path}, socket) do
    form =
      AshPhoenix.Form.remove_form(socket.assigns.form, path, validate_opts: [errors: false])

    {:noreply, assign(socket, form: form)}
  end

  defp apply_action(socket, :new, _) do
    form =
      AshPhoenix.Form.for_create(Article, :publish,
        actor: socket.assigns.current_user,
        forms: [
          auto?: true
        ]
      )
      |> to_form

    assign(socket, form: form)
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    case get_article_by_slug(slug, socket.assigns.current_user) do
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

  defp get_article_by_slug(slug, actor) do
    Articles.get_article_by_slug(slug, actor: actor, load: [:tags])
  end
end
