defmodule IspentWeb.ApiCategoryControllerTest do
  use IspentWeb.ConnCase, async: true

  import Ispent.AccountsFixtures

  alias Ispent.Accounts
  alias Ispent.Category
  alias Ispent.Expense
  alias Ispent.Repo

  test "lists only the authenticated user's categories", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    user_category = insert_category(user.id, "Food")
    insert_category(other_user.id, "Transport")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> get(~p"/api/categories")

    assert %{"categories" => [%{"id" => id, "name" => "Food", "icon" => "category"}]} =
             json_response(conn, 200)

    assert id == user_category.id
  end

  test "returns an empty list when the authenticated user has no categories", %{conn: conn} do
    user = user_fixture()
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> get(~p"/api/categories")

    assert json_response(conn, 200) == %{"categories" => []}
  end

  test "requires authentication to list categories", %{conn: conn} do
    conn = get(conn, ~p"/api/categories")

    assert json_response(conn, 401) == %{"error" => "unauthorized"}
  end

  test "creates a category for the authenticated user", %{conn: conn} do
    user = user_fixture()
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/categories", %{
        "category" => %{
          "name" => "Food",
          "icon" => "utensils",
          "user_id" => user.id + 1
        }
      })

    assert %{
             "category" => %{
               "id" => id,
               "name" => "Food",
               "icon" => "utensils",
               "is_active" => true,
               "parent_id" => nil
             }
           } = json_response(conn, 201)

    assert Repo.get!(Category, id).user_id == user.id
  end

  test "accepts mobile camelCase category attributes", %{conn: conn} do
    user = user_fixture()
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/categories", %{
        "category" => %{
          "name" => "Archived",
          "categoryIcon" => "archive",
          "isActive" => false,
          "parentID" => nil
        }
      })

    assert %{
             "category" => %{
               "name" => "Archived",
               "icon" => "archive",
               "is_active" => false,
               "parent_id" => nil
             }
           } = json_response(conn, 201)
  end

  test "returns validation errors for invalid category attributes", %{conn: conn} do
    user = user_fixture()
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/categories", %{"category" => %{"name" => "", "icon" => ""}})

    assert %{"errors" => %{"name" => [_], "icon" => [_]}} = json_response(conn, 422)
  end

  test "rejects a parent category owned by another user", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    parent = insert_category(other_user.id, "Other user's category")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/categories", %{
        "category" => %{
          "name" => "Food",
          "icon" => "utensils",
          "parent_id" => parent.id
        }
      })

    assert %{"errors" => %{"parent_id" => ["does not belong to the current user"]}} =
             json_response(conn, 422)
  end

  test "updates a category owned by the authenticated user", %{conn: conn} do
    user = user_fixture()
    category = insert_category(user.id, "Food")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/categories/#{category.id}", %{
        "category" => %{
          "name" => "Meals",
          "icon" => "utensils",
          "user_id" => user.id + 1
        }
      })

    assert %{"category" => %{"id" => id, "name" => "Meals", "icon" => "utensils"}} =
             json_response(conn, 200)

    assert id == category.id
    assert Repo.get!(Category, category.id).user_id == user.id
  end

  test "cannot update another user's category", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    category = insert_category(other_user.id, "Food")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/categories/#{category.id}", %{
        "category" => %{"name" => "Meals", "icon" => "utensils"}
      })

    assert json_response(conn, 404) == %{"error" => "category_not_found"}
    assert Repo.get!(Category, category.id).name == "Food"
  end

  test "rejects an invalid category ID when updating", %{conn: conn} do
    user = user_fixture()
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/categories/not-an-id", %{"category" => %{"name" => "Meals"}})

    assert json_response(conn, 400) == %{"error" => "invalid_category_id"}
  end

  test "returns validation errors for invalid updates", %{conn: conn} do
    user = user_fixture()
    category = insert_category(user.id, "Food")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/categories/#{category.id}", %{"category" => %{"name" => ""}})

    assert %{"errors" => %{"name" => [_]}} = json_response(conn, 422)
  end

  test "requires authentication", %{conn: conn} do
    conn = post(conn, ~p"/api/categories", %{"category" => %{"name" => "Food", "icon" => "food"}})

    assert json_response(conn, 401) == %{"error" => "unauthorized"}
  end

  test "requires category attributes", %{conn: conn} do
    user = user_fixture()
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/categories", %{})

    assert json_response(conn, 400) == %{"error" => "category_required"}
  end

  test "deletes a category owned by the authenticated user", %{conn: conn} do
    user = user_fixture()
    category = insert_category(user.id, "Food")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> delete(~p"/api/categories/#{category.id}")

    assert response(conn, 204) == ""
    assert Repo.get(Category, category.id) == nil
  end

  test "deactivates a category that has an expense", %{conn: conn} do
    user = user_fixture()
    category = insert_category(user.id, "Food")

    %Expense{}
    |> Expense.changeset(%{
      category_id: category.id,
      details: "Lunch",
      value: 12.5,
      datetime: ~D[2026-10-12]
    })
    |> Repo.insert!()

    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> delete(~p"/api/categories/#{category.id}")

    assert %{"category" => %{"id" => id, "is_active" => false}} = json_response(conn, 200)
    assert id == category.id
    assert Repo.get!(Category, category.id).is_active == false
  end

  test "cannot delete another user's category", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    category = insert_category(other_user.id, "Food")
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> delete(~p"/api/categories/#{category.id}")

    assert json_response(conn, 404) == %{"error" => "category_not_found"}
    assert Repo.get(Category, category.id)
  end

  test "rejects an invalid category ID", %{conn: conn} do
    user = user_fixture()
    token = Accounts.generate_user_api_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> delete(~p"/api/categories/not-an-id")

    assert json_response(conn, 400) == %{"error" => "invalid_category_id"}
  end

  test "requires authentication to delete a category", %{conn: conn} do
    conn = delete(conn, ~p"/api/categories/1")

    assert json_response(conn, 401) == %{"error" => "unauthorized"}
  end

  defp insert_category(user_id, name) do
    %Category{}
    |> Category.changeset(%{name: name, icon: "category", user_id: user_id})
    |> Repo.insert!()
  end
end
