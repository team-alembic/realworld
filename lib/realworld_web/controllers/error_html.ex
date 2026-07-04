defmodule RealworldWeb.ErrorHTML do
  @moduledoc """
  Renders HTML error pages.

  With no matching template, we fall back to the status message derived from the
  template name (e.g. "404.html" -> "Not Found").
  """
  use RealworldWeb, :html

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
