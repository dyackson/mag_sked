defmodule MagSked.Courts.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "snapshots" do
    field :court_number, :integer
    field :times_by_date, :map
    field :fetched_at, :utc_datetime
  end

  @doc false
  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:court_number, :times_by_date, :fetched_at])
    |> validate_required([:court_number, :fetched_at])
  end
end
