defmodule Realworld.Repo do
  use AshPostgres.Repo, otp_app: :realworld

  def installed_extensions do
    ["ash-functions"]
  end
end
