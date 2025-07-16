defmodule ShortCraft.MixProject do
  use Mix.Project

  def project do
    [
      app: :short_craft,
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
      mod: {ShortCraft.Application, []},
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
      # Phoenix Framework
      {:phoenix, "~> 1.7.14"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.1", override: true},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_ecto, "~> 4.5"},

      # Database & ORM
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # Authentication & Authorization
      {:argon2_elixir, "~> 3.0"},
      {:oauth2, "~> 2.0"},
      {:ueberauth, "~> 0.10"},
      {:ueberauth_google, "~> 0.12"},
      {:ueberauth_github, "~> 0.8"},
      {:ueberauth_facebook, "~> 0.8"},
      # {:ueberauth_twitter, "~> 0.4"}, # Temporarily disabled due to httpoison version conflict

      # Asset Pipeline
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},

      # Email & HTTP
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:httpoison, "~> 2.1"},

      # Background Jobs & Scheduling
      {:oban, "~> 2.17"},

      # Monitoring & Telemetry
      {:telemetry_metrics, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.0"},

      # Utilities
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:plug_cowboy, "~> 2.5"},
      {:timex, "~> 3.7"},
      {:briefly, "~> 0.5"},

      # Testing
      {:floki, ">= 0.30.0", only: :test}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind short_craft", "esbuild short_craft"],
      "assets.deploy": [
        "tailwind short_craft --minify",
        "esbuild short_craft --minify",
        "phx.digest"
      ]
    ]
  end
end
