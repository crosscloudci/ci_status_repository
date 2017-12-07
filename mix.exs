defmodule CncfDashboardApi.Mixfile do
  use Mix.Project

  def project do
    [app: :cncf_dashboard_api,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {CncfDashboardApi, []},
     applications: [:ex_machina, :retry, :phoenix, :gproc, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext, :phoenix_ecto, :postgrex, :yaml_elixir, :timex, :timex_ecto]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.5"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
     {:quantum, ">= 2.1.0"},
     {:sidetask, "~> 1.1"},
     {:timex, "~> 3.0"},
     {:timex_ecto, "~> 3.0"},
     {:ecto_conditionals, "~> 0.1.0"},
     {:yaml_elixir, "~> 1.3.1"},
     {:cors_plug, "~> 1.2"},
     {:ex_machina, "~> 2.0"},
     {:gproc, "0.3.1"},
     {:joken, "~> 1.2.1"},
     {:retry, "~> 0.8"},
     {:guardian, "~> 0.12.0"},
     {:export, "~> 0.1.1"}]

  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
