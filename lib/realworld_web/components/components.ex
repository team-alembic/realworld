defmodule RealworldWeb.Components do
  use Phoenix.Component

  attr :path, :string, required: true
  attr :path_info, :list, required: true

  def nav_link(assigns) do
    current_path = Path.join(["/" | assigns.path_info])

    class =
      case assigns.href do
        ^current_path -> "nav-link active"
        _ -> "nav-link"
      end

    ~H"""
    <a class={class} href={@href}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
