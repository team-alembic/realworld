defmodule RealworldWeb.ArticleLive.CommentsComponent do
  use RealworldWeb, :live_component

  alias AshPhoenix.Form
  alias Realworld.Articles.Comment

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> new_comment_form(assigns[:current_user]) end)

    {:ok, socket}
  end

  def handle_event(
        "post-comment",
        %{"comment" => %{"body" => body}},
        %{assigns: %{form: form, article_id: article_id}} = socket
      ) do
    case Form.submit(form, params: %{body: body, article_id: article_id}) do
      {:ok, _comment} ->
        {:noreply, assign(socket, form: new_comment_form(socket.assigns[:current_user]))}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("delete-comment", %{"id" => id}, socket) do
    Realworld.Articles.destroy_comment!(id, actor: socket.assigns[:current_user])

    {:noreply, socket}
  end

  defp new_comment_form(current_user) do
    Comment
    |> Form.for_create(:create, as: "comment", forms: [auto?: true], actor: current_user)
    |> to_form()
  end
end
