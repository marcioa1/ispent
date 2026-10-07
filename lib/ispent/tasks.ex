defmodule Ispent.Tasks do
  @moduledoc """
  Small reusable tasks for the application.

  Add task functions here when they do not belong to a specific domain context.
  """

  @doc """
  Prints a message to standard output.
  """
  @spec print_message(String.t()) :: :ok
  def print_message(message) when is_binary(message) do
    IO.puts("message")
  end

  def create_user(email, password) do
    alias Ispent.Accounts
    alias Ispent.Repo

    Repo.delete_all(Ispent.Accounts.UserToken)
    # Repo.delete_all(Ispent.Accounts.User)

    case Accounts.get_user_by_email(email) do
      nil ->
        {:ok, _user} =
          Accounts.register_user(%{
            "email" => email,
            "password" => password
          })

        IO.puts("User #{email} created successfully.")

      _user ->
        IO.puts("User #{email} already exists. Skipping.")
    end
  end
end
