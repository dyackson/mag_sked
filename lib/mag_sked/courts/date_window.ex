defmodule MagSked.Courts.DateWindow do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Schema

  alias MagSked.Repo

  @primary_key {:id, :integer, autogenerate: false}
  schema "date_windows" do
    field :first, :date
    field :last, :date
    timestamps(type: :utc_datetime)
  end

  def get, do: Repo.get(__MODULE__, 1)

  def save(first, last) do
    %__MODULE__{id: 1}
    |> cast(%{first: first, last: last}, [:first, :last])
    |> validate_required([:first, :last])
    |> Repo.insert(
      conflict_target: :id,
      on_conflict: {:replace, [:first, :last, :updated_at]}
    )
  end
end
