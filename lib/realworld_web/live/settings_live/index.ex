defmodule RealworldWeb.SettingsLive.Index do
  use RealworldWeb, :live_view
  alias AshPhoenix.Form
  alias Realworld.Accounts
  alias Realworld.Accounts.User

  @impl true
  def mount(_params, %{"user" => "user?id=" <> user_id}, socket) do
    user =
      User
      |> Accounts.get!(user_id)

    form =
      user
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
