[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  import_deps: [:phoenix, :ash, :ash_postgres, :ash_authentication, :ash_authentication_phoenix],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"]
]
