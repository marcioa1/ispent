defmodule IspentWeb.ApiAuthControllerTest do
  use IspentWeb.ConnCase, async: true

  import Ispent.AccountsFixtures

  alias Ispent.Accounts

  setup do
    user = user_fixture() |> set_password()
    %{user: user}
  end

  test "login returns a bearer token that authenticates the user", %{conn: conn, user: user} do
    conn =
      post(conn, ~p"/api/auth/login", %{
        "email" => user.email,
        "password" => valid_user_password()
      })

    assert %{"access_token" => token, "token_type" => "Bearer"} = json_response(conn, 200)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get(~p"/api/auth/me")

    assert %{"user" => %{"id" => id, "email" => email}} = json_response(conn, 200)
    assert id == user.id
    assert email == user.email
  end

  test "login rejects invalid credentials", %{conn: conn, user: user} do
    conn =
      post(conn, ~p"/api/auth/login", %{
        "email" => user.email,
        "password" => "incorrect password"
      })

    assert json_response(conn, 401) == %{"error" => "invalid_credentials"}
  end

  test "protected endpoint rejects missing or invalid bearer tokens", %{conn: conn} do
    assert conn
           |> get(~p"/api/auth/me")
           |> json_response(401) == %{"error" => "unauthorized"}

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer invalid-token")
      |> get(~p"/api/auth/me")

    assert json_response(conn, 401) == %{"error" => "unauthorized"}
  end

  test "logout revokes the bearer token", %{conn: conn, user: user} do
    conn =
      post(conn, ~p"/api/auth/login", %{
        "email" => user.email,
        "password" => valid_user_password()
      })

    %{"access_token" => token} = json_response(conn, 200)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> delete(~p"/api/auth/logout")

    assert response(conn, 204) == ""
    assert Accounts.get_user_by_api_token(token) == nil
  end
end
