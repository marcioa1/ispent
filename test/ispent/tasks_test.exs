defmodule Ispent.TasksTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Ispent.Tasks

  test "print_message writes the message to standard output" do
    assert capture_io(fn -> Tasks.print_message("Hello, world!") end) == "Hello, world!\n"
  end
end
