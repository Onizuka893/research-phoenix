defmodule Research.Repo do
  use Ecto.Repo,
    otp_app: :research,
    adapter: Ecto.Adapters.Postgres
end
