defmodule Ispent.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :icon, :string, null: false
      add :parent_id, references(:categories, on_delete: :nilify_all)
      timestamps()
    end

    create index(:categories, [:user_id])
    create index(:categories, [:parent_id])
  end
end
