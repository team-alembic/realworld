defmodule RealworldWeb.CoreComponents do
  @moduledoc """
  Core UI components.

  This application's UI is built with the RealWorld "Conduit" stylesheet, not
  Tailwind CSS, so the Tailwind/heroicons components that `phx.new` generates
  (modal, flash, table, input, icon, ...) were unused and have been removed.
  Only `simple_form/1` — the one component the app actually renders — remains.
  """
  use Phoenix.Component

  @doc """
  Renders a form.

  ## Example

      <.simple_form for={@form} phx-submit="save">
        <%= text_input(f, :title) %>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end
end
