defmodule MagSked.Repo do
  use Ecto.Repo,
    otp_app: :mag_sked,
    adapter: Ecto.Adapters.SQLite3
end
