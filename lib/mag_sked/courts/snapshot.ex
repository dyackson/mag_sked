defmodule MagSked.Courts.Snapshot do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias MagSked.Repo

  schema "snapshots" do
    field :court_number, :integer
    field :times_by_date, :map
    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:court_number, :times_by_date])
    |> validate_required([:court_number, :times_by_date])
  end

  def get_latest do
    latest =
      from(s in __MODULE__,
        group_by: s.court_number,
        select: %{id: max(s.id)}
      )

    from(s in __MODULE__,
      join: l in subquery(latest),
      on: s.id == l.id,
      select: {s.court_number, s.times_by_date}
    )
    |> Repo.all()
    |> Map.new()
  end

  def save(court_number, times_by_date) do
    %{court_number: court_number, times_by_date: times_by_date}
    |> changeset()
    |> Repo.insert()
  end
end
