defmodule Ispent.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :icon, :string
    belongs_to :user, Ispent.Accounts.User
    belongs_to :parent, Ispent.Category, foreign_key: :parent_id
    has_many :subcategories, Ispent.Category, foreign_key: :parent_id

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :icon, :user_id, :parent_id])
    |> validate_required([:name, :icon, :user_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:parent_id)
    |> unsafe_validate_unique([:user_id, :name], Ispent.Repo)
    |> unique_constraint([:user_id, :name])
  end
end
