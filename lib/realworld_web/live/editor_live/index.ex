defmodule RealworldWeb.EditorLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Accounts.User
  alias Realworld.Articles.Article

  def mount(_params, session, socket) do
    socket = assign_user_id(socket, session)
    user = Realworld.Accounts.get!(User, socket.assigns.user_id)

    form = AshPhoenix.Form.for_create(Article, :publish, api: Realworld.Articles, actor: user)

    {:ok, assign(socket, form: form)}
  end

  defp assign_user_id(socket, session) do
    case fetch_user_id(session) do
      {:ok, user_id} -> assign(socket, :user_id, user_id)
      {:error, reason} -> put_flash(socket, :error, reason)
    end
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", _params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form) do
      {:ok, result} ->
        # Do something with the result, like redirect
        IO.inspect(result)
        {:noreply, redirect(socket, to: "/article/#{result.slug}")}

      {:error, form} ->
        IO.inspect(form)
        {:noreply, assign(socket, :form, form)}
    end
  end

  @spec fetch_user_id(map()) :: {:ok, String.t()} | {:error, any()}
  defp fetch_user_id(session) do
    case Map.fetch(session, "user") do
      {:ok, user_param} ->
        user_param =
          String.split(user_param, "?")
          |> List.last()
          |> URI.decode_query()

        {:ok, user_param["id"]}

      :error ->
        {:error, "User is not logged in"}
    end
  end
end
