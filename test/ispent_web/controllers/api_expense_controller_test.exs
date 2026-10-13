defmodule IspentWeb.ApiExpenseControllerTest do
  use IspentWeb.ConnCase, async: true

  import Ispent.AccountsFixtures

  alias Ispent.Accounts
  alias Ispent.Category
  alias Ispent.Expense
  alias Ispent.Repo

  test "lists only expenses belonging to the authenticated user's categories", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    category = insert_category(user.id, "Food")
    other_category = insert_category(other_user.id, "Food")
    expense = insert_expense(category.id, "Lunch")
    insert_expense(other_category.id, "Other user's lunch")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> get(~p"/api/expenses")

    assert %{"expenses" => [%{"id" => id, "details" => "Lunch"}]} = json_response(conn, 200)
    assert id == expense.id
  end

  test "creates an expense using mobile field names", %{conn: conn} do
    user = user_fixture()
    category = insert_category(user.id, "Food")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/expenses", %{
        "expense" => %{
          "categoryID" => category.id,
          "details" => "Lunch",
          "value" => 12.5,
          "datetime" => "2026-10-12T13:30:00Z",
          "latitude" => 38.7223,
          "longitude" => -9.1393,
          "locationName" => "Lisbon"
        }
      })

    assert %{
             "expense" => %{
               "id" => id,
               "category_id" => category_id,
               "details" => "Lunch",
               "value" => 12.5,
               "datetime" => "2026-10-12T13:30:00Z",
               "location_name" => "Lisbon",
               "extraordinary" => false
             }
           } = json_response(conn, 201)

    assert category_id == category.id
    assert Repo.get!(Expense, id).extraordinary == false
  end

  test "rejects creating an expense in another user's category", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    category = insert_category(other_user.id, "Other food")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/expenses", %{
        "expense" => %{
          "category_id" => category.id,
          "details" => "Lunch",
          "value" => 12.5,
          "datetime" => "2026-10-12T13:30:00Z"
        }
      })

    assert %{"errors" => %{"category_id" => ["does not belong to the current user"]}} =
             json_response(conn, 422)
  end

  test "updates an expense owned by the authenticated user", %{conn: conn} do
    user = user_fixture()
    category = insert_category(user.id, "Food")
    expense = insert_expense(category.id, "Lunch")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/expenses/#{expense.id}", %{
        "expense" => %{"details" => "Dinner", "extraordinary" => true}
      })

    assert %{
             "expense" => %{
               "id" => id,
               "details" => "Dinner",
               "extraordinary" => true
             }
           } = json_response(conn, 200)

    assert id == expense.id
  end

  test "cannot update or delete another user's expense", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    category = insert_category(other_user.id, "Food")
    expense = insert_expense(category.id, "Lunch")
    token = Accounts.generate_user_api_token(user)

    update_conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/expenses/#{expense.id}", %{
        "expense" => %{"details" => "Changed"}
      })

    assert json_response(update_conn, 404) == %{"error" => "expense_not_found"}

    delete_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> delete(~p"/api/expenses/#{expense.id}")

    assert json_response(delete_conn, 404) == %{"error" => "expense_not_found"}
    assert Repo.get!(Expense, expense.id).details == "Lunch"
  end

  test "deletes an expense owned by the authenticated user", %{conn: conn} do
    user = user_fixture()
    category = insert_category(user.id, "Food")
    expense = insert_expense(category.id, "Lunch")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> delete(~p"/api/expenses/#{expense.id}")

    assert response(conn, 204) == ""
    assert Repo.get(Expense, expense.id) == nil
  end

  test "requires authentication", %{conn: conn} do
    conn = get(conn, ~p"/api/expenses")

    assert json_response(conn, 401) == %{"error" => "unauthorized"}
  end

  defp insert_category(user_id, name) do
    %Category{}
    |> Category.changeset(%{name: name, icon: "category", user_id: user_id})
    |> Repo.insert!()
  end

  defp insert_expense(category_id, details) do
    %Expense{}
    |> Expense.changeset(%{
      category_id: category_id,
      details: details,
      value: 12.5,
      datetime: ~U[2026-10-12 13:30:00Z]
    })
    |> Repo.insert!()
  end
end
