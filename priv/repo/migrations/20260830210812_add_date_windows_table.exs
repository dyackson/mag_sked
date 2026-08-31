defmodule MagSked.Repo.Migrations.AddDateWindowsTable do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE date_windows (
      id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
      first DATE NOT NULL,
      last DATE NOT NULL,
      inserted_at DATETIME NOT NULL,
      updated_at DATETIME NOT NULL,
      CHECK (first <= last)
    )
    """
  end

  def down do
    drop table(:date_windows)
  end
end
