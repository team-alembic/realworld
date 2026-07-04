defmodule RealworldWeb.Components do
  use Phoenix.Component

  attr :href, :string, required: true
  attr :path_info, :list, required: true
  slot :inner_block, required: true

  def nav_link(assigns) do
    current_path = Path.join(["/" | assigns.path_info])

    class =
      case assigns.href do
        ^current_path -> "nav-link active"
        _ -> "nav-link"
      end

    assigns = assign(assigns, :class, class)

    ~H"""
    <a class={@class} href={@href}>
      {render_slot(@inner_block)}
    </a>
    """
  end
end
