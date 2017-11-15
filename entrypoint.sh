#!/bin/bash
cat << ENV_FILE > /backend/config/dev.secret.exs
use Mix.Config
config :cncf_dashboard_api, CncshboardApi.Repo,
adapter: Ecto.Adapters.Postgres,
username: "${DB_USER}",
password: "${DB_PASSWORD}",
database: "${DB_NAME}",
hostname: "${DB_HOST}",
ownership_timeout: 300_000,
timeout: 300_000,
pool_timeout: 300_000,
pool: Ecto.Adapters.SQL.Sandbox
ENV_FILE

mix ecto.create && mix ecto.migrate
mix phoenix.server
