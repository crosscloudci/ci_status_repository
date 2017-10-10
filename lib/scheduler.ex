require Logger;
require IEx;
defmodule CncfDashboardApi.Scheduler do
  use Quantum.Scheduler, otp_app: :cncf_dashboard_api
end
