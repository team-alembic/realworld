defmodule RealworldWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use RealworldWeb, :controller
      use RealworldWeb, :html

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """
  def static_paths do
    ~w(assets fonts images favicon.ico robots.txt)
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: RealworldWeb.Layouts]

      import Plug.Conn
      use Gettext, backend: RealworldWeb.Gettext
      import Phoenix.LiveView.Controller
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include shared imports and aliases for HTML rendering
      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {RealworldWeb.Layouts, :live}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: RealworldWeb.Gettext
    end
  end

  defp html_helpers do
    quote do
      alias Phoenix.LiveView.JS

      use Gettext, backend: RealworldWeb.Gettext

      # HTML escaping plus the phoenix_html / phoenix_html_helpers form + tag builders
      # (text_input/2, submit/2, etc.) that the Conduit form templates rely on
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # LiveView and .heex helpers (assigns, slots, <.form>, live_patch, etc.)
      import Phoenix.Component

      # Project components and helpers
      import RealworldWeb.CoreComponents
      import RealworldWeb.Components
      import RealworldWeb.ErrorHelpers
      import RealworldWeb.LiveHelpers

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: RealworldWeb.Endpoint,
        router: RealworldWeb.Router,
        statics: RealworldWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
