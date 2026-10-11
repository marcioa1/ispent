defmodule Ispent.Categories do
  @moduledoc """
  The Categories context.
  """

  alias Ispent.Accounts.Scope
  alias Ispent.Category
  alias Ispent.Repo

  @doc """
  Lists the categories owned by the user in the given scope.
  """
  def list_categories(%Scope{user: user}) do
    Category.get_all_by_user(user.id)
  end

  @doc """
  Creates a category owned by the user in the given scope.
  """
  def create_category(%Scope{user: user}, attrs) when is_map(attrs) do
    attrs =
      attrs
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> Map.put("user_id", user.id)

    changeset =
      %Category{}
      |> Category.changeset(attrs)
      |> validate_parent_ownership(user.id)

    Repo.insert(changeset)
  end

  defp validate_parent_ownership(changeset, user_id) do
    case Ecto.Changeset.get_field(changeset, :parent_id) do
      nil ->
        changeset

      parent_id ->
        if Repo.get_by(Category, id: parent_id, user_id: user_id) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :parent_id, "does not belong to the current user")
        end
    end
  end
end
