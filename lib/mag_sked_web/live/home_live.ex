defmodule MagSkedWeb.HomeLive do
  use MagSkedWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen">
      <h1 class="text-4xl font-bold text-gray-900">Welcome to your Stupid App!</h1>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
