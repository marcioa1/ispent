defmodule IspentWeb.ApiCategoryControllerTest do
  use IspentWeb.ConnCase, async: true

  import Ispent.AccountsFixtures

  alias Ispent.Accounts
  alias Ispent.Category
  alias Ispent.Repo

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

  defp insert_category(user_id, name) do
    %Category{}
    |> Category.changeset(%{name: name, icon: "category", user_id: user_id})
    |> Repo.insert!()
  end
end
