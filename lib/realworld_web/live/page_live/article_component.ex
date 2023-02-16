defmodule RealworldWeb.PageLive.ArticleComponent do
  use RealworldWeb, :live_component

  def handle_event("read-more", %{"slug" => slug}, socket) do
    {:noreply, redirect(socket, to: "/article/#{slug}")}
  end
end
