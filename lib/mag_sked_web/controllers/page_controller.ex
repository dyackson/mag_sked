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

  @day_begins Time.new(9, 0, 0)
  def grid_classes(court, span) do
    [start | _] = span
    start_row = (start <> ":00") |> Time.from_iso8601!() |> Time.diff(@day_begins, :minute) |> div(30)

    "col-start-#{court + 1} row-start-#{start_row} row-span-#{length(span)}"
  end
end
