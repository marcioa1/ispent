defmodule IspentWeb.ApiExpenseController do
  use IspentWeb, :controller

  alias Ispent.Expenses
  alias IspentWeb.CoreComponents

  def index(conn, _params) do
    expenses =
      conn.assigns.current_scope
      |> Expenses.list_expenses()
      |> Enum.map(&expense_json/1)

    json(conn, %{expenses: expenses})
  end

  def create(conn, %{"expense" => attrs}) when is_map(attrs) do
    case Expenses.create_expense(conn.assigns.current_scope, attrs) do
      {:ok, expense} ->
        conn
        |> put_status(:created)
        |> json(%{expense: expense_json(expense)})

      {:error, changeset} ->
        render_changeset_errors(conn, changeset)
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "expense_required"})
  end

  def update(conn, %{"id" => id, "expense" => attrs}) when is_map(attrs) do
    with {:ok, expense_id} <- parse_id(id) do
      case Expenses.update_expense(conn.assigns.current_scope, expense_id, attrs) do
        {:ok, expense} ->
          json(conn, %{expense: expense_json(expense)})

        {:error, :not_found} ->
          not_found(conn)

        {:error, changeset} ->
          render_changeset_errors(conn, changeset)
      end
    else
      :error -> invalid_id(conn)
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "expense_required"})
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, expense_id} <- parse_id(id) do
      case Expenses.delete_expense(conn.assigns.current_scope, expense_id) do
        {:ok, _expense} -> send_resp(conn, :no_content, "")
        {:error, :not_found} -> not_found(conn)
        {:error, changeset} -> render_changeset_errors(conn, changeset)
      end
    else
      :error -> invalid_id(conn)
    end
  end

  def delete(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "expense_id_required"})
  end

  defp parse_id(id) do
    case Integer.parse(id) do
      {expense_id, ""} when expense_id > 0 -> {:ok, expense_id}
      _ -> :error
    end
  end

  defp invalid_id(conn) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_expense_id"})
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "expense_not_found"})
  end

  defp render_changeset_errors(conn, changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, &CoreComponents.translate_error/1)

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: errors})
  end

  defp expense_json(expense) do
    %{
      id: expense.id,
      category_id: expense.category_id,
      details: expense.details,
      value: expense.value,
      datetime: expense.datetime,
      latitude: expense.latitude,
      longitude: expense.longitude,
      location_name: expense.location_name,
      extraordinary: expense.extraordinary,
      inserted_at: expense.inserted_at,
      updated_at: expense.updated_at
    }
  end
end
