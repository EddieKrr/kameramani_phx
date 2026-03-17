[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs,css}", "{config,lib,test}/**/*.{heex,ex,exs,css}", "priv/*/seeds.exs"]
]
