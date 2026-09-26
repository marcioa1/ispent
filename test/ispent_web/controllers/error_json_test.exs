defmodule IspentWeb.ErrorJSONTest do
  use IspentWeb.ConnCase, async: true

  test "renders 404" do
    assert IspentWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert IspentWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
