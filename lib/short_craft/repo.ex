defmodule ShortCraft.Repo do
  use Ecto.Repo,
    otp_app: :short_craft,
    adapter: Ecto.Adapters.Postgres
end
