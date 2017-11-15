use Mix.Config
config :cncf_dashboard_api, CncfDashboardApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "user",
  password: "database",
  database: "backend",
  hostname: "postgres",
  ownership_timeout: 300_000,
  timeout: 300_000,
  pool_timeout: 300_000,
  pool: Ecto.Adapters.SQL.Sandbox

