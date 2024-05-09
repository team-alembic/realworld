defmodule RealworldWeb.SettingsLive.Index do
  use RealworldWeb, :live_view
  alias AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    form =
      socket.assigns.current_user
      |> Form.for_update(:update,
        as: "user",
        forms: [auto?: true],
        actor: socket.assigns.current_user
      )

    {:ok, assign(socket, form: form)}
  end

  @impl true
  def handle_event("logout", _, socket) do
    {:noreply, redirect(socket, to: ~p"/sign-out")}
  end
end
