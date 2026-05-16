defmodule MagSkedWeb.PageController do
  use MagSkedWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
