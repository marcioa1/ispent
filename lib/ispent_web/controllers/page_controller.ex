defmodule IspentWeb.PageController do
  use IspentWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
