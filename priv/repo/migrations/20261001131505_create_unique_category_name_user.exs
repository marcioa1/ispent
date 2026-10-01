defmodule Ispent.Repo.Migrations.CreateUniqueCategoryNameUser do
  use Ecto.Migration

  def change do
    create unique_index(:categories, [:name, :user_id], name: :unique_category_name_user)
  end
end
