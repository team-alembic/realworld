defmodule RealworldWeb.AuthLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Accounts.User
  alias AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :register, _params) do
    socket
    |> assign(:form_id, "sign-up-form")
    |> assign(:cta, "Sign up")
    |> assign(:alternative, "Have an account?")
    |> assign(:alternative_path, ~p"/login")
    |> assign(:action, ~p"/auth/user/password/register")
    |> assign(
      :form,
      Form.for_create(User, :register_with_password, as: "user")
    )
  end

  defp apply_action(socket, :login, _params) do
    socket
    |> assign(:form_id, "sign-in-form")
    |> assign(:cta, "Sign in")
    |> assign(:alternative, "Need an account?")
    |> assign(:alternative_path, ~p"/register")
    |> assign(:action, ~p"/auth/user/password/sign_in")
    |> assign(
      :form,
      Form.for_action(User, :sign_in_with_password, as: "user")
    )
  end
end
