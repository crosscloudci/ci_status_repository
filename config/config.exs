# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :cncf_dashboard_api,
  ecto_repos: [CncfDashboardApi.Repo]

# Configures the endpoint
config :cncf_dashboard_api, CncfDashboardApi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "5rHE04iK3g7lTiTsR8GbnvMHenR/kuIEDsL2g7889CuYO+wkiUceZhltOqA3kLfr",
  render_errors: [view: CncfDashboardApi.ErrorView, accepts: ~w(html json)],
  pubsub: [name: CncfDashboardApi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

config :cncf_dashboard_api, CncfDashboardApi.Scheduler,
 jobs: [
    # Every minute
    # {"* * * * *",      {Heartbeat, :send, []}},
     # {"*/15 * * * *",      {CncfDashboardApi., :send, []}},
    # Every 15 minutes
    # {"*/15 * * * *",   fn -> System.cmd("rm", ["/tmp/tmp_"]) end},
    # Runs on 18, 20, 22, 0, 2, 4, 6:
    # {"0 18-6/2 * * *", fn -> :mnesia.backup('/var/backup/mnesia') end},
   # Runs every midnight:
   # {"@daily",         {Backup, :backup, []}}
 ]
config :joken, config_module: Guardian.JWT

config :guardian, Guardian,
  # issuer: "CncfDashboardApi",
  # ttl: { 30, :days },
  # verify_issuer: false,
  serializer: CncfDashboardApi.GuardianSerializer,
  atoms: [:listen, :publish, :crews, :email, :name, :id]

