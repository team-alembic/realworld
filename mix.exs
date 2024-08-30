defmodule Realworld.MixProject do
  use Mix.Project

  def project do
    [
      app: :realworld,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Realworld.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.6", override: true},
      {:phoenix_view, "~> 2.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.16"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      # {:ash, "~> 3.0"},
      {:ash, github: "ash-project/ash", override: true},
      {:ash_postgres, "~> 2.0"},
      {:ash_authentication, "~> 4.0"},
      {:ash_authentication_phoenix, "~> 2.0"},
      {:picosat_elixir, "~> 0.2"},
      {:slugify, "~> 1.3"},
      {:earmark, "~> 1.4"},
      {:faker, "~> 0.18", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
