use Mix.Config
config :cncf_dashboard_api, CncfDashboardApi.Repo,
adapter: Ecto.Adapters.Postgres,
username: System.get_env("DB_USERNAME"),
password: System.get_env("DB_PASSWORD"),
database: System.get_env("DB_NAME"),
hostname: System.get_env("DB_HOST"),
pool_size:System.get_env("DB_POOL_SIZE")
