defmodule Ispent.Repo do
  use Ecto.Repo,
    otp_app: :ispent,
    adapter: Ecto.Adapters.Postgres
end
