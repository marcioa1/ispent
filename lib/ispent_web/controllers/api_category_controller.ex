defmodule IspentWeb.ApiCategoryController do
  use IspentWeb, :controller

  alias Ispent.Categories
  alias IspentWeb.CoreComponents

  def index(conn, _params) do
    categories =
      conn.assigns.current_scope
      |> Categories.list_categories()
      |> Enum.map(&category_json/1)

    json(conn, %{categories: categories})
  end

  def create(conn, %{"category" => attrs}) when is_map(attrs) do
    scope = conn.assigns.current_scope
    attrs = normalize_category_attrs(attrs)

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

  defp normalize_category_attrs(attrs) do
    attrs
    |> rename_attribute("categoryIcon", "icon")
    |> rename_attribute("category_icon", "icon")
    |> rename_attribute("isActive", "is_active")
    |> rename_attribute("parentID", "parent_id")
  end

  defp rename_attribute(attrs, external_name, internal_name) do
    if Map.has_key?(attrs, external_name) do
      value = Map.fetch!(attrs, external_name)

      attrs
      |> Map.delete(external_name)
      |> Map.put_new(internal_name, value)
    else
      attrs
    end
  end
end
