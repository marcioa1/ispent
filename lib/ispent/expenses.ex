defmodule Ispent.Expenses do
  @moduledoc """
  The Expenses context.
  """

  import Ecto.Query

  alias Ispent.Accounts.Scope
  alias Ispent.Category
  alias Ispent.Expense
  alias Ispent.Repo

  @doc """
  Lists expenses whose categories belong to the user in the given scope.
  """
  def list_expenses(%Scope{user: user}) do
    Repo.all(
      from expense in Expense,
        join: category in assoc(expense, :category),
        where: category.user_id == ^user.id,
        order_by: [desc: expense.datetime, desc: expense.id]
    )
  end

  @doc """
  Creates an expense attached to one of the user's categories.
  """
  def create_expense(%Scope{user: user}, attrs) when is_map(attrs) do
    attrs =
      attrs
      |> normalize_attrs()
      |> Map.drop(["user_id"])

    changeset =
      %Expense{}
      |> Expense.changeset(attrs)
      |> validate_category_ownership(user.id)

    Repo.insert(changeset)
  end

  @doc """
  Updates an expense whose category belongs to the user in the given scope.
  """
  def update_expense(%Scope{user: user}, expense_id, attrs)
      when is_integer(expense_id) and is_map(attrs) do
    case get_expense_by_user(expense_id, user.id) do
      nil ->
        {:error, :not_found}

      expense ->
        attrs =
          attrs
          |> normalize_attrs()
          |> Map.drop(["user_id"])

        changeset =
          expense
          |> Expense.changeset(attrs)
          |> validate_category_ownership(user.id)

        Repo.update(changeset)
    end
  end

  @doc """
  Deletes an expense whose category belongs to the user in the given scope.
  """
  def delete_expense(%Scope{user: user}, expense_id) when is_integer(expense_id) do
    case get_expense_by_user(expense_id, user.id) do
      nil -> {:error, :not_found}
      expense -> Repo.delete(expense)
    end
  end

  defp get_expense_by_user(expense_id, user_id) do
    Repo.one(
      from expense in Expense,
        join: category in assoc(expense, :category),
        where: expense.id == ^expense_id and category.user_id == ^user_id,
        select: expense
    )
  end

  defp validate_category_ownership(changeset, user_id) do
    case Ecto.Changeset.get_field(changeset, :category_id) do
      nil ->
        changeset

      category_id ->
        if Repo.get_by(Category, id: category_id, user_id: user_id) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :category_id, "does not belong to the current user")
        end
    end
  end

  defp normalize_attrs(attrs) do
    attrs
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
    |> rename_attribute("categoryID", "category_id")
    |> rename_attribute("categoryId", "category_id")
    |> rename_attribute("locationName", "location_name")
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
