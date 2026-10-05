defmodule IspentWeb.ApiAuthController do
  use IspentWeb, :controller

  alias Ispent.Accounts

  def create(conn, %{"email" => email, "password" => password})
      when is_binary(email) and is_binary(password) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_credentials"})

      user ->
        token = Accounts.generate_user_api_token(user)
        json(conn, %{access_token: token, token_type: "Bearer"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "email_and_password_required"})
  end

  def show(conn, _params) do
    user = conn.assigns.current_scope.user
    json(conn, %{user: %{id: user.id, email: user.email}})
  end

  def delete(conn, _params) do
    Accounts.delete_user_api_token(conn.assigns.api_token)
    send_resp(conn, 204, "")
  end
end
