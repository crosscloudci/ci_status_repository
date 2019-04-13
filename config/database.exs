use Mix.Config
config :cncf_dashboard_api, CncfDashboardApi.Repo,
adapter: Ecto.Adapters.Postgres,
username: System.get_env("DB_USERNAME"),
password: System.get_env("DB_PASSWORD"),
database: System.get_env("DB_NAME"),
hostname: System.get_env("DB_HOST"),
pool_size: System.get_env("DB_POOL_SIZE")

config :guardian, Guardian,
  allowed_algos: ["HS256"], # optional
  secret_key: System.get_env("JWT_KEY"),
  # verify_module: Guardian.JWT,  # optional
  issuer: System.get_env("JWT_ISSUER")
  # ttl: { 30, :days },
  # allowed_drift: 2000,
  # verify_issuer: true, # optional
