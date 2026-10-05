defmodule Ispent.Repo.Migrations.AddIsActiveToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :is_active, :boolean, default: true, null: false
    end
  end
end
