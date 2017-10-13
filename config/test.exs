use Mix.Config
import_config "test.secret.exs"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cncf_dashboard_api, CncfDashboardApi.Endpoint,
http: [port: 4001],
server: false

# Print only warnings and errors during test
config :logger, level: :info

