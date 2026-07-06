# ![RealWorld Example App](logo.png)

> ### Ash + Phoenix LiveView codebase containing real world examples (CRUD, auth, advanced patterns, etc) that adheres to the [RealWorld](https://github.com/gothinkster/realworld) spec.

This codebase demonstrates a fully fledged fullstack application — the Medium-clone "Conduit" — built with the [Ash Framework](https://ash-hq.org/) and **Phoenix LiveView**: CRUD, authentication, authorization policies, pagination, real-time updates, and more.

For how Conduit works with other frontends/backends, head over to the [RealWorld](https://github.com/gothinkster/realworld) repo.

## Getting started

### Prerequisites

- Erlang and Elixir as pinned in [`.tool-versions`](.tool-versions) (works with [asdf](https://asdf-vm.com)/[mise](https://mise.jdx.dev): `asdf install`)
- PostgreSQL (any recent version; connection settings live in `config/dev.exs`)

### One command

```
mix setup
```

fetches dependencies, creates and migrates the database, and seeds demo data. Then:

```
mix phx.server
```

and open [`localhost:4000`](http://localhost:4000). Sign in as **`demo@example.com` / `password123!`** (the seeds also create `alice`, `bob` and `carol` with the same password, plus tagged articles, follows, favorites and comments — see [`priv/repo/seeds.exs`](priv/repo/seeds.exs)). Re-seed any time with `mix seed`.

### Tests

```
mix test
```

sets up the test database automatically. Before pushing, `mix precommit` runs the full gate: compile with warnings as errors, unused-dependency check, formatting, and the test suite.

## A tour of the code

The domain layer is three [Ash domains](https://hexdocs.pm/ash/Ash.Domain.html), each exposing a **code interface** — plain functions the web layer calls with an `actor:` option, so authorization always runs:

| Domain | Resources | Worth reading for |
| --- | --- | --- |
| `Realworld.Accounts` | `User`, `Token` | AshAuthentication (register/sign-in actions, token revocation on logout), the policy split between library bypass and explicit anonymous access, self-only updates |
| `Realworld.Articles` | `Article`, `Tag`, `ArticleTag`, `Comment`, `Favorite` | Derived attributes (slug, sanitized markdown), `manage_relationship` for tags, a paginated/filtered feed preparation, aggregates & calculations, PubSub notifiers, upserts |
| `Realworld.Profiles` | `Follow` | The smallest complete example: actor-scoped reads, idempotent upsert creates, policy-guarded destroys |

Every resource, action and notable attribute also carries a DSL `description`, so introspection tools (and `iex> Ash.Resource.Info.*`) are self-documenting.

Things to know that aren't obvious from the RealWorld spec:

- **Articles store two bodies.** Authors write markdown into `body_raw`; the `RenderMarkdown` change renders it to *sanitized* HTML in `body` (via [MDEx](https://hexdocs.pm/mdex)), which is the only reason the article page can safely use `raw/1`. No action ever accepts `body` or `slug` directly.
- **Policies are on by default.** All three domains set `authorize :by_default`; each resource declares its own policies. `Token` is deny-by-default behind AshAuthentication's bypass check.
- **Real-time comes from the data layer.** `Comment` and `Favorite` broadcast via `Ash.Notifier.PubSub` on create/destroy; the LiveViews subscribe per-article, so open pages update live.
- **The conduit theme is vendored** at `assets/vendor/main.css` (its original CDN no longer exists) and bundled by esbuild together with `assets/css/app.css`.

### The tests are the documentation

The test suite is written to teach. Each domain test file is a worked example of the concepts its resource demonstrates — start with:

- [`test/realworld/articles/resources/article_test.exs`](test/realworld/articles/resources/article_test.exs) — publishing, tag management, author-only policies, `Ash.can?/2`, aggregates vs calculations
- [`test/realworld/accounts/resources/user_test.exs`](test/realworld/accounts/resources/user_test.exs) — registration, sign-in, Forbidden-vs-Invalid errors, the self-only update policy
- [`test/realworld/articles/resources/list_articles_test.exs`](test/realworld/articles/resources/list_articles_test.exs) — filtering, pagination, the personal feed

The LiveView tests (under `test/realworld_web/live/`) drive the UI with [PhoenixTest](https://hexdocs.pm/phoenix_test); `test/support/data_case.ex` shows the "your actions are the factory" approach to test data — no fixture library, everything goes through real actions.

## Deploying

Standard Phoenix release. In production two secrets must be present in the environment (both can be generated with `mix phx.gen.secret`):

- `SECRET_KEY_BASE` — signs cookies
- `TOKEN_SIGNING_SECRET` — signs AshAuthentication's tokens

along with `DATABASE_URL` and `PHX_HOST` (see [`config/runtime.exs`](config/runtime.exs)). Build assets with `mix assets.deploy`.

## Sending a Pull Request

The consultants at Alembic are monitoring for pull requests when they are "on the beach" (aka when they are not billable or working with a client). We will review your pull request and either merge it, request changes to it, or close it with an explanation. For changes raised when there are no consultants on the beach, please expect some delay. We will do our best to provide update and feedback throughout the process.
