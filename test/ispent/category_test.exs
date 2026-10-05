defmodule Ispent.CategoryTest do
  use Ispent.DataCase

  alias Ispent.Category
  import Ispent.AccountsFixtures

  test "a user cannot have two categories with the same name" do
    user = user_fixture()
    attrs = %{name: "Food", icon: "food", user_id: user.id}

    assert {:ok, _category} = %Category{} |> Category.changeset(attrs) |> Repo.insert()

    assert {:error, changeset} = %Category{} |> Category.changeset(attrs) |> Repo.insert()
    assert "has already been taken" in errors_on(changeset).name
  end

  test "different users can have categories with the same name" do
    user1 = user_fixture()
    user2 = user_fixture()
    attrs1 = %{name: "Food", icon: "food", user_id: user1.id}
    attrs2 = %{name: "Food", icon: "food", user_id: user2.id}
    assert user1.id != user2.id
    assert {:ok, _category1} = %Category{} |> Category.changeset(attrs1) |> Repo.insert()
    assert {:ok, _category2} = %Category{} |> Category.changeset(attrs2) |> Repo.insert()
  end

  test "get_all_by_user returns only the user's categories" do
    user1 = user_fixture()
    user2 = user_fixture()
    category1 = insert_category(user1.id, "Food")
    category2 = insert_category(user1.id, "Transport")
    insert_category(user2.id, "Books")

    categories = Category.get_all_by_user(user1.id)

    assert Enum.sort(Enum.map(categories, & &1.id)) == Enum.sort([category1.id, category2.id])
  end

  test "get_active_by_user returns only active categories belonging to the user" do
    user1 = user_fixture()
    user2 = user_fixture()
    active_category = insert_category(user1.id, "Food")

    inactive_category =
      user1.id
      |> insert_category("Transport")
      |> Category.changeset(%{is_active: false})
      |> Repo.update!()

    insert_category(user2.id, "Books")

    categories = Category.get_active_by_user(user1.id)

    assert Enum.map(categories, & &1.id) == [active_category.id]
    refute inactive_category.id in Enum.map(categories, & &1.id)
  end

  test "is_parent? reports whether a category has subcategories" do
    user = user_fixture()
    root = insert_category(user.id, "Food")
    child = insert_category(user.id, "Fruit", root.id)
    leaf = insert_category(user.id, "Drinks")

    assert Category.is_parent?(root.id)
    refute Category.is_parent?(leaf.id)
    assert Category.has_parent?(child.id)
    refute Category.has_parent?(root.id)
  end

  test "a category cannot have itself as a parent" do
    user = user_fixture()
    category = insert_category(user.id, "Food")

    changeset = Category.changeset(category, %{parent_id: category.id})
    assert "cannot be the same as the category's own ID" in errors_on(changeset).parent_id

    refute Category.changeset(category, %{parent_id: category.id}).valid?
  end

  test "a category cannot have a parent and subcategories at the same time" do
    user = user_fixture()
    root = insert_category(user.id, "Food")
    child = insert_category(user.id, "Fruit", root.id)
    other_root = insert_category(user.id, "Drinks")

    grandchild_changeset =
      Category.changeset(%Category{}, %{
        name: "Citrus",
        icon: "category",
        user_id: user.id,
        parent_id: child.id
      })

    assert "cannot have a parent and subcategories at the same time" in errors_on(
             grandchild_changeset
           ).parent_id

    root_changeset = Category.changeset(root, %{parent_id: other_root.id})

    assert "cannot have a parent and subcategories at the same time" in errors_on(root_changeset).parent_id

    assert Category.changeset(root, %{name: "Meals"}).valid?
    assert Category.changeset(child, %{parent_id: other_root.id}).valid?
  end

  defp insert_category(user_id, name, parent_id \\ nil) do
    %Category{}
    |> Category.changeset(%{name: name, icon: "category", user_id: user_id, parent_id: parent_id})
    |> Repo.insert!()
  end
end
