# CNCF Dashboard API

To start the CNCF DashBoard API server

  * Install Elixir and Erlang
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Load initial project and cloud data:
    ```
    mix gitlab_data.load_projects
    mix gitlab_data.load_clouds
    ```
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `. .env ; mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


## Dashboard Backend configuration

Create a .env file and update the setting (see [.env.example](.env.example)):

```
export GITLAB_API="https://YOUR_GITLAB_HOST/api/v4"
export GITLAB_TOKEN="YOUR_GITLAB_TOKEN"
export GITLAB_CI_YML="https://YOUR_GITLAB_CROSS_CLOUD_HOST/cncf/cross-cloud/raw/ci-stable-v0.1.0/cross-cloud.yml"
export PORT=YOUR_DASHBOARD_PORT
```


## To run tests

After setup for running sever above ^^^

  * Setup test DB `MIX_ENV=test mix ecto.migrate`
  * Run tests `. .env; iex -S mix test --only wip --trace`
