defmodule MagSkedWeb.PageController do
  use MagSkedWeb, :controller

  alias MagSked.Courts

  # Full page: shell + the availability fragment rendered inline for the
  # first paint (works before/without JS).
  def home(conn, _params) do
    render(conn, :home, snapshot: Courts.snapshot(), one_week_away: one_week_away())
  end

  # Bare fragment polled by htmx. No root layout, no app layout — just the
  # availability markup, so htmx can morph it into the existing page.
  def availability(conn, _params) do
    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> render(:availability, snapshot: Courts.snapshot(), one_week_away: one_week_away())
  end

  defp one_week_away, do: "Europe/Lisbon" |> DateTime.now!() |> DateTime.shift(week: 1)
end
