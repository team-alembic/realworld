defmodule RealworldWeb.PageLive.Index do
  use RealworldWeb, :live_view
  alias Realworld.Articles.Article

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_offset, 0)
      |> assign(:page_limit, 20)
      |> assign(:filter_tag, nil)
      |> assign(:filter_author, nil)
      |> assign(:filter_favourited, nil)
      |> assign(:articles, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    case Article.list_articles(
           nil,
           page: [limit: socket.assigns.page_limit, offset: socket.assigns.page_offset]
         ) do
      {:ok, page} ->
        socket |> assign(:articles, page.results)

      _ ->
        put_flash(socket, :error, "Unable to fetch articles. Please try again later.")
    end
  end
end
