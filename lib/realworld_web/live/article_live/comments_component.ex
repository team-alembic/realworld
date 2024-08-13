defmodule RealworldWeb.ArticleLive.CommentsComponent do
  use RealworldWeb, :live_component

  alias AshPhoenix.Form
  alias Realworld.Articles.Comment

  def update(assigns, socket) do
    # ? should this go here or in the parent?
    form =
      Form.for_create(Comment, :create,
        as: "comment",
        forms: [auto?: true],
        actor: assigns[:current_user]
      )
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(form: form)

    {:ok, socket}
  end

  def handle_event(
        "post-comment",
        %{"comment" => %{"body" => body}},
        %{assigns: %{form: form, article_id: article_id}} = socket
      ) do
    case Form.submit(form, params: %{body: body, article_id: article_id}) do
      {:ok, _} ->
        {:noreply, assign(socket, form: form)}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end

    {:noreply, socket}
  end

  def handle_event("delete-comment", %{"id" => id}, socket) do
    Realworld.Articles.destroy_comment!(id, actor: socket.assigns[:current_user])

    {:noreply, socket}
  end
end
