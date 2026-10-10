defmodule IspentWeb.ApiCategoryController do
  use IspentWeb, :controller

  alias Ispent.Categories
  alias IspentWeb.CoreComponents

  def create(conn, %{"category" => attrs}) when is_map(attrs) do
    scope = conn.assigns.current_scope

    case Categories.create_category(scope, attrs) do
      {:ok, category} ->
        conn
        |> put_status(:created)
        |> json(%{category: category_json(category)})

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, &CoreComponents.translate_error/1)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "category_required"})
  end

  defp category_json(category) do
    %{
      id: category.id,
      name: category.name,
      icon: category.icon,
      is_active: category.is_active,
      parent_id: category.parent_id,
      inserted_at: category.inserted_at,
      updated_at: category.updated_at
    }
  end
end
