defmodule Ispent.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :category_id, references(:categories, on_delete: :restrict), null: false
      add :details, :string, null: false
      add :value, :float, null: false
      add :datetime, :date, null: false
      add :latitude, :float
      add :longitude, :float
      add :location_name, :string
      add :extraordinary, :boolean, default: false, null: false

      timestamps()
    end

    create index(:expenses, [:category_id])
  end
end
