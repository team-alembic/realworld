defmodule Realworld.Accounts.TokenTest do
  @moduledoc """
  Exercises the `Token` resource's policies.

  Tokens are internal to AshAuthentication (session revocation via the `:jti`
  session identifier, sign-in tokens), so the resource is **deny-by-default**
  with a single bypass: `AshAuthentication.Checks.AshAuthenticationInteraction`.
  That check passes when the request context carries the private
  `ash_authentication?: true` flag, which AshAuthentication's own machinery sets
  on every internal call — this test sets it by hand to show how the bypass
  works.

  Note the extension defines only purpose-built actions (`:get_token`,
  `:revoke_token`, `:read_expired`, ...) — there is no primary `:read`, so we
  exercise a named action.
  """
  use Realworld.DataCase, async: true

  alias Realworld.Accounts.Token

  test "direct access is forbidden, with or without an actor" do
    user = build_user()

    query = Ash.Query.for_read(Token, :read_expired)

    assert {:error, %Ash.Error.Forbidden{}} = Ash.read(query)
    assert {:error, %Ash.Error.Forbidden{}} = Ash.read(query, actor: user)
  end

  test "AshAuthentication's internal context passes the bypass" do
    # This is exactly what AshAuthentication does internally — application code
    # should never need to set this flag itself.
    assert {:ok, _tokens} =
             Token
             |> Ash.Query.set_context(%{private: %{ash_authentication?: true}})
             |> Ash.Query.for_read(:read_expired)
             |> Ash.read()
  end
end
