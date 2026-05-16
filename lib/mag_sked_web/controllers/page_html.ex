defmodule MagSkedWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MagSkedWeb, :html

  embed_templates "page_html/*"

  @doc "Sorted union of all slot times across courts (table row labels)."
  def slot_times(snapshot) do
    snapshot.courts
    |> Enum.flat_map(fn court -> Enum.map(court.slots, & &1.time) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Light/dark/system toggle for dead views.

  Identical in look to `Layouts.theme_toggle/1`, but uses a plain `onclick`
  instead of `phx-click`, since there is no LiveView JS runtime on this page.
  It dispatches the same `phx:set-theme` DOM event that the listener in
  root.html.heex already handles, so theming logic stays in one place.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />
      <button
        :for={theme <- ~w(system light dark)}
        class="flex p-2 cursor-pointer w-1/3"
        data-phx-theme={theme}
        onclick="this.dispatchEvent(new CustomEvent('phx:set-theme', {bubbles: true}))"
      >
        <.icon name={theme_icon(theme)} class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  defp theme_icon("system"), do: "hero-computer-desktop-micro"
  defp theme_icon("light"), do: "hero-sun-micro"
  defp theme_icon("dark"), do: "hero-moon-micro"
end
