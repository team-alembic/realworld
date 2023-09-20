defmodule RealworldWeb.AuthLive.AuthForm do
  use RealworldWeb, :live_component
  alias AshPhoenix.Form

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    form = socket.assigns.form |> Form.validate(params, errors: false)

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params, read_one?: true, before_submit: &Ash.Changeset.set_context(&1, %{token_type: :sign_in})) do
      {:ok, user} ->
        path =
          Routes.auth_path(
            socket.endpoint,
            {:user, :password,
             :sign_in_with_token},
            token: user.__metadata__.token
          )

        {:noreply, redirect(socket, to: path)}

      {:error, form} ->
        {:noreply,
         assign(socket, :form, Form.clear_value(form, [:password, :password_confirmation]))}
    end
  end
end
