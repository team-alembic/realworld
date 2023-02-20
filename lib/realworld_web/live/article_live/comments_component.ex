defmodule RealworldWeb.ArticleLive.CommentsComponent do
  use RealworldWeb, :live_component

  alias AshPhoenix.Form
  alias Realworld.Articles
  alias Realworld.Articles.Comment

  def update(assigns, socket) do
    # ? should this go here or in the parent?
    form =
      Form.for_create(Comment, :create,
        api: Realworld.Articles,
        as: "comment",
        forms: [auto?: true]
      )

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
    comment = Enum.find(socket.assigns.comments, &(&1.id == id))

    Articles.destroy(comment)

    {:noreply, socket}
  end
end
