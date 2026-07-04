defmodule RealworldWeb.Layouts do
  @moduledoc """
  Function-component layouts for the application.

  The `root`, `app` and `live` layouts are compiled from the `.heex` files in
  `layouts/` via `embed_templates/1`, and referenced as `{RealworldWeb.Layouts, :root}`
  (root layout, set in the router) and `{RealworldWeb.Layouts, :app | :live}`
  (the wrapping layout for controllers and LiveViews respectively).
  """
  use RealworldWeb, :html

  embed_templates "layouts/*"
end
