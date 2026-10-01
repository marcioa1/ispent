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
end
