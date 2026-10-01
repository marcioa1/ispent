defmodule Ispent.Category do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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
    |> unsafe_validate_unique([:name, :user_id], Ispent.Repo)
    |> unique_constraint([:name, :user_id], name: :unique_category_name_user)
    |> validate_parent_id_is_not_self()
    |> validate_parent_and_child_exclusivity()
  end

  def is_parent?(category_id) do
    Ispent.Repo.exists?(
      from category in __MODULE__,
        where: category.parent_id == ^category_id
    )
  end

  def has_parent?(category_id) do
    Ispent.Repo.exists?(
      from category in __MODULE__,
        where: category.id == ^category_id and not is_nil(category.parent_id)
    )
  end

  defp validate_parent_id_is_not_self(changeset) do
    parent_id = get_field(changeset, :parent_id)
    category_id = get_field(changeset, :id)

    if parent_id && category_id && parent_id == category_id do
      add_error(changeset, :parent_id, "cannot be the same as the category's own ID")
    else
      changeset
    end
  end

  defp validate_parent_and_child_exclusivity(changeset) do
    parent_id = get_field(changeset, :parent_id)
    category_id = get_field(changeset, :id)

    category_has_children? = category_id && is_parent?(category_id)
    parent_has_parent? = parent_id && has_parent?(parent_id)

    if parent_id && (category_has_children? || parent_has_parent?) do
      add_error(changeset, :parent_id, "cannot have a parent and subcategories at the same time")
    else
      changeset
    end
  end
end
