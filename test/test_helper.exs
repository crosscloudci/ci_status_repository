{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start
Ecto.Adapters.SQL.Sandbox.mode(CncfDashboardApi.Repo, :manual)
# Ecto.Adapters.SQL.Sandbox.mode(CncfDashboardApi.Repo, {:shared, self()})

