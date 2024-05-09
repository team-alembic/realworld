defmodule RealworldWeb.SettingsLive.Form do
  use RealworldWeb, :live_component
  alias AshPhoenix.Form

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:trigger_action, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    form = socket.assigns.form |> Form.validate(params, errors: false)

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    form = socket.assigns.form |> Form.validate(params)

    socket =
      socket
      |> assign(:form, form)
      |> assign(:errors, Form.errors(form))

    submit_form(form, socket)
  end

  defp submit_form(%{valid?: true} = form, socket) do
    case Form.submit(form) do
      {:ok, user} ->
        {:noreply, redirect(socket, to: ~p"/profile/#{user.username}")}

      {:error, form} ->
        assign(socket, :form, form)
    end
  end

  defp submit_form(_form, socket) do
    {:noreply, socket}
  end
end
