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
    IO.puts(message)
  end
end
