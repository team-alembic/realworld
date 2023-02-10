defmodule RealworldWeb.SettingsLive.Index do
  use RealworldWeb, :live_view
  alias AshPhoenix.Form
  alias Realworld.Accounts

  @impl true
  def mount(_params, _session, socket) do
    form =
      socket.assigns.current_user
      |> Form.for_update(:update,
        api: Accounts,
        as: "user",
        forms: [auto?: true]
      )

    {:ok, assign(socket, form: form)}
  end

  @impl true
  def handle_event("logout", _, socket) do
    {:noreply, redirect(socket, to: Routes.auth_path(socket, :sign_out))}
  end
end
