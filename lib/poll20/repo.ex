defmodule Poll20.Repo do
  use AshPostgres.Repo,
    otp_app: :poll20

  def min_pg_version, do: %Version{major: 17, minor: 0, patch: 0}

  def installed_extensions, do: ["ash-functions"]
end
