defmodule IspentWeb.ApiAuthentication do
  @behaviour Plug

  import Plug.Conn

  alias Ispent.Accounts
  alias Ispent.Accounts.Scope

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    with {:ok, token} <- bearer_token(conn),
         user when not is_nil(user) <- Accounts.get_user_by_api_token(token) do
      conn
      |> assign(:current_scope, Scope.for_user(user))
      |> assign(:api_token, token)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "unauthorized"})
        |> halt()
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      [header] ->
        case String.split(header, " ", parts: 2) do
          [scheme, token] when token != "" ->
            if String.downcase(scheme) == "bearer", do: {:ok, token}, else: :error

          _ ->
            :error
        end

      _ ->
        :error
    end
  end
end
