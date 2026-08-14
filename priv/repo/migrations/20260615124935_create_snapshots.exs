defmodule MagSked.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots) do
      add :court_number, :integer
      add :times_by_date, :map
      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
