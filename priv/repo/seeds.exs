# Demo data for local development. Run with:
#
#     mix run priv/repo/seeds.exs
#
# Everything goes through the domain actions (never raw inserts), so policies,
# identities and side effects (slugs, markdown rendering, tag management) are
# exercised exactly as they are in the app. Re-running is safe: users are
# looked up by username first, and articles/follows/favorites upsert or are
# skipped when they already exist.

alias Realworld.Accounts
alias Realworld.Accounts.User
alias Realworld.Articles
alias Realworld.Articles.Article
alias Realworld.Articles.Comment
alias Realworld.Profiles

password = "password123!"

find_or_register = fn username, email, bio ->
  case Accounts.get_user_by_username(username, not_found_error?: false) do
    {:ok, %User{} = user} ->
      user

    {:ok, nil} ->
      User
      |> Ash.Changeset.for_create(:register_with_password, %{
        username: username,
        email: email,
        password: password
      })
      |> Ash.create!()
      |> then(fn user ->
        user
        |> Ash.Changeset.for_update(:update, %{bio: bio}, actor: user)
        |> Ash.update!()
      end)
  end
end

demo = find_or_register.("demo", "demo@example.com", "I'm the demo account — log in as me!")
alice = find_or_register.("alice", "alice@example.com", "Functional programming enthusiast.")
bob = find_or_register.("bob", "bob@example.com", "Phoenix core stan. Writes about the web.")
carol = find_or_register.("carol", "carol@example.com", "Ash Framework early adopter.")

IO.puts("Users ready: demo/alice/bob/carol (password: #{password})")

publish = fn author, title, description, body_raw, tags ->
  case Articles.get_article_by_slug(Slug.slugify(title), not_found_error?: false) do
    {:ok, %Article{} = article} ->
      article

    {:ok, nil} ->
      Article
      |> Ash.Changeset.for_create(
        :publish,
        %{
          title: title,
          description: description,
          body_raw: body_raw,
          tags: Enum.map(tags, &%{name: &1})
        },
        actor: author
      )
      |> Ash.create!()
  end
end

articles = [
  {alice, "Pattern Matching Beyond the Basics",
   "Function heads, guards, and the pin operator in anger.",
   """
   Elixir's pattern matching goes far beyond destructuring.

   ## Function heads

   Order your clauses from **most** to *least* specific — the first match wins.

   ```elixir
   def handle(%{status: :ok} = result), do: result
   def handle(_), do: :error
   ```
   """, ~w(elixir patterns)},
  {alice, "Processes Are Cheap, Use Them",
   "The BEAM's unit of concurrency is not a thread.",
   "Spawning a process costs ~2KB. Design with **millions** in mind, not dozens.",
   ~w(elixir otp)},
  {bob, "LiveView Without the JavaScript Guilt",
   "Server-rendered interactivity that still feels instant.",
   """
   ## Why LiveView

   - Diffs over the wire
   - One language end to end
   - `phx-hook` when you *really* need JS
   """, ~w(phoenix liveview)},
  {bob, "Verified Routes Are a Superpower",
   "~p catches broken links at compile time.",
   "Change a route and `mix compile` tells you every stale path. **No more 404 hunts.**",
   ~w(phoenix)},
  {carol, "Declarative Resources with Ash",
   "Model your domain once, derive everything else.",
   """
   Actions, policies, calculations and pubsub all live on the resource.

   > The resource is the single source of truth.
   """, ~w(ash elixir)},
  {carol, "Policies: Authorization That Reads Like Prose",
   "actor_present, relates_to_actor_via, and friends.",
   "A policy block per action type keeps authorization **next to the data** it protects.",
   ~w(ash security)},
  {carol, "Testing Ash Actions Without Fixtures",
   "Your actions are the factory.",
   "Create test data through the same actions users hit — policies included.",
   ~w(ash testing)}
]

published = Enum.map(articles, fn {author, t, d, b, tags} -> publish.(author, t, d, b, tags) end)

IO.puts("Articles ready: #{length(published)}")

# Follows (idempotent: :follow upserts).
for {follower, target} <- [
      {demo, alice},
      {demo, carol},
      {alice, bob},
      {bob, alice},
      {carol, alice}
    ] do
  Profiles.follow!(target.id, actor: follower)
end

# Favorites (idempotent: :add_favorite upserts).
[first, second, third | _] = published

for {user, article} <- [
      {demo, first},
      {demo, third},
      {alice, third},
      {bob, first},
      {carol, second}
    ] do
  Articles.favorite!(article.id, actor: user)
end

comment = fn article, user, body ->
  existing =
    Comment
    |> Ash.Query.for_read(:comments_by_article, %{article_id: article.id})
    |> Ash.read!()

  unless Enum.any?(existing, &(&1.body == body && &1.user_id == user.id)) do
    Comment
    |> Ash.Changeset.for_create(:create, %{body: body, article_id: article.id}, actor: user)
    |> Ash.create!()
  end
end

comment.(first, bob, "The pin operator finally clicked for me. Thanks!")
comment.(first, demo, "Great writeup — sharing with my team.")
comment.(third, alice, "Hooks-when-needed is exactly the right framing.")

IO.puts("Follows, favorites and comments ready.")
IO.puts("Log in at http://localhost:4000/login as demo@example.com / #{password}")
