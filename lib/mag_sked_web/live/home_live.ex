defmodule MagSkedWeb.HomeLive do
  use MagSkedWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="fixed z-50 top-[calc(1rem+env(safe-area-inset-top))] right-[calc(1rem+env(safe-area-inset-right))]">
      <Layouts.theme_toggle />
    </div>
    <div class="flex flex-col items-center justify-center min-h-dvh">
      <h1 class="text-4xl font-bold text-base-content">Welcome to your Stupid App!</h1>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
