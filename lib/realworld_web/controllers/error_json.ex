defmodule RealworldWeb.ErrorJSON do
  @moduledoc """
  Renders JSON error responses, e.g. `%{errors: %{detail: "Not Found"}}`.
  """
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
