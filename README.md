# ![RealWorld Example App](logo.png)

> ### Ash + Phoenix LiveView codebase containing real world examples (CRUD, auth, advanced patterns, etc) that adheres to the [RealWorld](https://github.com/gothinkster/realworld) spec and API.


### [Demo](https://realworld-ash.fly.dev/)&nbsp;&nbsp;&nbsp;&nbsp;[RealWorld](https://github.com/gothinkster/realworld)


This codebase was created to demonstrate a fully fledged fullstack application built with **Ash** + **Phoenix LiveView** including CRUD operations, authentication, routing, pagination, and more.

We've gone to great lengths to adhere to the **Ash** + **Phoenix LiveView** community styleguides & best practices.

For more information on how to this works with other frontends/backends, head over to the [RealWorld](https://github.com/gothinkster/realworld) repo.


# How it works

> A fullstack phoenix liveview application with backend built with [Ash Framework](https://ash-hq.org/).

### Prerequisites

* erlang 25.2 and elixir 1.14.2-otp-25
* PostgreSQL 14.6

### Installation

1. Clone the repo
   ```
   git clone https://github.com/team-alembic/realworld.git
   ```
2. Install dependencies
   ```
   cd realworld
   mix deps.get
   ```
3. Create a postgres database and run migration with ash_postgres
   ```
   mix ash.setup && mix ash.migrate
   ```

### Test
1. Create a test database and run migration with ash_postgres
   ```
   MIX_ENV=test mix ash_postgres.create && MIX_ENV=test mix ash.migrate
   ```

2. Run the tests
   ```
   mix test
   ```

# Getting started

To start your Phoenix server:

  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# Sending a Pull Request
The consultants at Alembic are monitoring for pull requests when they are “on the beach” (aka when they are not billable or working with a client). We will review your pull request and either merge it, request changes to it, or close it with an explanation. For changes raised when there are no consultants on the beach, please expect some delay. We will do our best to provide update and feedback throughout the process.
