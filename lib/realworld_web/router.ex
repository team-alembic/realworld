defmodule RealworldWeb.Router do
  use RealworldWeb, :router
  use AshAuthentication.Phoenix.Router

  alias AshAuthentication.Phoenix.LiveSession

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {RealworldWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", RealworldWeb do
    pipe_through :browser

    auth_routes_for Realworld.Accounts.User, to: AuthController

    live "/login", AuthLive.Index, :login
    live "/profile/:username", ProfileLive.Index, :profile
    live "/register", AuthLive.Index, :register
    live "/", PageLive.Index, :index
  end

  scope "/", RealworldWeb do
    pipe_through([:browser, :require_authenticated_user])

    sign_out_route AuthController

    live_session :authenticated, on_mount: LiveSession, session: {LiveSession, :generate_session, []} do
      live "/editor", EditorLive.Index, :index
    end

    live "/settings", SettingsLive.Index, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", RealworldWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RealworldWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
