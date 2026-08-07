defmodule MagSked.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots) do
      add :court_number, :integer
      add :times_by_date, :map
      add :fetched_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
