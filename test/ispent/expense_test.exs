defmodule Ispent.ExpenseTest do
  use Ispent.DataCase

  alias Ispent.Category
  alias Ispent.Expense
  import Ispent.AccountsFixtures

  test "creates an expense with the requested attributes" do
    user = user_fixture()

    {:ok, category} =
      %Category{}
      |> Category.changeset(%{name: "Food", icon: "food", user_id: user.id})
      |> Repo.insert()

    attrs = %{
      category_id: category.id,
      details: "Lunch",
      value: 12.5,
      datetime: ~D[2026-10-12],
      latitude: 38.7223,
      longitude: -9.1393,
      location_name: "Lisbon",
      extraordinary: true
    }

    assert {:ok, expense} =
             %Expense{}
             |> Expense.changeset(attrs)
             |> Repo.insert()

    assert expense.category_id == category.id
    assert expense.details == "Lunch"
    assert expense.value == 12.5
    assert expense.datetime == ~D[2026-10-12]
    assert expense.latitude == 38.7223
    assert expense.longitude == -9.1393
    assert expense.location_name == "Lisbon"
    assert expense.extraordinary
  end

  test "requires category, details, value, and date" do
    changeset = Expense.changeset(%Expense{}, %{})

    assert %{
             category_id: ["can't be blank"],
             details: ["can't be blank"],
             value: ["can't be blank"],
             datetime: ["can't be blank"]
           } =
             errors_on(changeset)
  end
end
