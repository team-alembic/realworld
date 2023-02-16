defmodule RealworldWeb.LiveHelpers do
  import Phoenix.Component

  alias Realworld.Accounts
  alias Realworld.Accounts.User

  def assign_defaults(%{"user" => "user?id=" <> user_id}, socket) do
    current_user = User |> Accounts.get!(user_id)

    socket
    |> assign(current_user: current_user)
  end

  def assign_defaults(_session, socket) do
    socket
    |> assign(current_user: nil)
  end

  def format_datetime(nil) do
    ""
  end

  def format_datetime(%{day: day, month: month, year: year}) do
    "#{format_month(month)} #{day}, #{year}"
  end

  def format_datetime(datetime) do
    %{day: day, month: month, year: year} = NaiveDateTime.from_iso8601!(datetime)
    "#{format_month(month)} #{day}, #{year}"
  end

  defp format_month(1), do: "January"
  defp format_month(2), do: "February"
  defp format_month(3), do: "March"
  defp format_month(4), do: "April"
  defp format_month(5), do: "May"
  defp format_month(6), do: "June"
  defp format_month(7), do: "July"
  defp format_month(8), do: "August"
  defp format_month(9), do: "September"
  defp format_month(10), do: "October"
  defp format_month(11), do: "November"
  defp format_month(12), do: "December"
end
