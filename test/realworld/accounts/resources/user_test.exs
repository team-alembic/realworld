defmodule Realworld.Accounts.UserTest do
  @moduledoc """
  Exercises the Accounts domain (the `User` resource) and doubles as a worked
  example of testing AshAuthentication and resource policies.

  Concepts demonstrated here:

    * the actions AshAuthentication's password strategy adds to the resource:
      `:register_with_password` (a create) and `:sign_in_with_password` (a read)
    * why those actions run **anonymously**: our `AuthLive` submits them with a
      nil actor, so the resource carries explicit `always()` policies for
      registration and reads — the `AshAuthenticationInteraction` bypass only
      covers AshAuthentication's *internal* calls (session loading, tokens)
    * authentication failures surfacing as `Ash.Error.Forbidden` without
      revealing *which* credential was wrong
    * a **self-only update policy** (`expr(id == ^actor(:id))`), checked both by
      performing the action and with `Ash.can?/2`
    * identities (`unique_email`/`unique_username`) surfacing as
      `Ash.Error.Invalid`
  """
  use Realworld.DataCase, async: true

  alias Realworld.Accounts
  alias Realworld.Accounts.User

  defp register(attrs) do
    User
    |> Ash.Changeset.for_create(:register_with_password, attrs)
    |> Ash.create()
  end

  defp sign_in(email, password) do
    User
    |> Ash.Query.for_read(:sign_in_with_password, %{email: email, password: password})
    |> Ash.read_one()
  end

  describe "register_with_password (create)" do
    test "registers a user without an actor" do
      email = email()

      # Registration is the one create anyone may call: the policy on
      # `action(:register_with_password)` is `authorize_if always()`.
      assert {:ok, user} =
               register(%{email: email, username: username(), password: password()})

      assert to_string(user.email) == email
    end

    test "hashes the password and never stores the plaintext" do
      password = password()

      {:ok, user} = register(%{email: email(), username: username(), password: password})

      # The strategy writes only `hashed_password` (`sensitive? true`); the
      # plaintext exists solely as an action argument.
      assert is_binary(user.hashed_password)
      refute user.hashed_password == password
    end

    test "returns a sign-in token in the record metadata" do
      {:ok, user} = register(%{email: email(), username: username(), password: password()})

      # With `tokens do enabled? true end` the register action also signs the
      # user in, putting a token in `__metadata__` for the web layer to use.
      assert is_binary(user.__metadata__.token)
    end

    test "enforces the unique_email and unique_username identities" do
      existing = build_user()

      assert {:error, %Ash.Error.Invalid{}} =
               register(%{email: existing.email, username: username(), password: password()})

      assert {:error, %Ash.Error.Invalid{}} =
               register(%{email: email(), username: existing.username, password: password()})
    end

    test "requires a password" do
      assert {:error, %Ash.Error.Invalid{}} =
               register(%{email: email(), username: username()})
    end
  end

  describe "sign_in_with_password (read)" do
    test "returns the user (with a token) for correct credentials" do
      password = password()
      user = build_user(password: password)

      # Sign-in is a *read action* returning at most one user; policies allow
      # reads for everyone, which is what lets this run with no actor.
      assert {:ok, %User{} = signed_in} = sign_in(user.email, password)
      assert signed_in.id == user.id
      assert is_binary(signed_in.__metadata__.token)
    end

    test "rejects a wrong password as Forbidden" do
      user = build_user()

      # `AuthenticationFailed` has error class `:forbidden`. Note the error is
      # the same for a bad password or an unknown email — it deliberately does
      # not reveal which credential failed.
      assert {:error, %Ash.Error.Forbidden{}} = sign_in(user.email, "not-the-password")
    end

    test "rejects an unknown email the same way" do
      assert {:error, %Ash.Error.Forbidden{}} = sign_in(email(), password())
    end
  end

  describe "get_user_by_username/2 (read :get_by_username, get? true)" do
    test "finds a user by username" do
      user = build_user()

      assert {:ok, %User{} = found} = Accounts.get_user_by_username(user.username)
      assert found.id == user.id
    end

    test "reports a missing username as NotFound (or nil on request)" do
      # As with all `get?` reads, no match is a NotFound error wrapped in the
      # `Ash.Error.Invalid` error class...
      assert {:error, %Ash.Error.Invalid{}} = Accounts.get_user_by_username("nobody")

      # ...or `{:ok, nil}` when asked politely.
      assert {:ok, nil} = Accounts.get_user_by_username("nobody", not_found_error?: false)
    end
  end

  describe "update (update :update, self only)" do
    test "a user can update their own profile" do
      user = build_user()

      assert {:ok, updated} =
               user
               |> Ash.Changeset.for_update(:update, %{bio: "Hi, I write Elixir."}, actor: user)
               |> Ash.update()

      assert updated.bio == "Hi, I write Elixir."
    end

    test "another user cannot update the profile (Forbidden)" do
      user = build_user()
      other = build_user()

      # The update policy is `authorize_if expr(id == ^actor(:id))`.
      assert {:error, %Ash.Error.Forbidden{}} =
               user
               |> Ash.Changeset.for_update(:update, %{bio: "hijacked"}, actor: other)
               |> Ash.update()
    end

    test "an anonymous update is Forbidden" do
      user = build_user()

      assert {:error, %Ash.Error.Forbidden{}} =
               user
               |> Ash.Changeset.for_update(:update, %{bio: "hijacked"})
               |> Ash.update()
    end

    test "Ash.can?/2 reports the policy result without performing the action" do
      user = build_user()
      other = build_user()

      assert Ash.can?({user, :update}, user)
      refute Ash.can?({user, :update}, other)
    end
  end

  describe "read policy" do
    test "profiles are readable without an actor" do
      user = build_user()

      # Public profile pages depend on anonymous reads being allowed.
      assert {:ok, %User{}} = Accounts.get_user_by_username(user.username, actor: nil)
    end
  end
end
