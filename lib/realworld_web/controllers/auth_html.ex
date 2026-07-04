defmodule RealworldWeb.AuthHTML do
  @moduledoc """
  HTML views for `RealworldWeb.AuthController` (e.g. the authentication
  failure page), compiled from the templates in `auth_html/`.
  """
  use RealworldWeb, :html

  embed_templates "auth_html/*"
end
