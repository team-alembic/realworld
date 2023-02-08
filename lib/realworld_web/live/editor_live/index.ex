defmodule RealworldWeb.EditorLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Articles.Article

  def mount(_params, _session, socket) do
    form = AshPhoenix.Form.for_create(Article, :publish, api: Realworld.Articles)

    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", _params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form) do
      {:ok, result} ->
        # Do something with the result, like redirect
        IO.inspect(result)
        {:noreply, socket}

      {:error, form} ->
        IO.inspect(form)
        {:noreply, assign(socket, :form, form)}
    end
  end
end
