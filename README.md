# CNCF Dashboard API server

**Prerequisites:** Erlang 20.1, Elixir 1.5.1, Ruby 2.2.1, Node v7.6.0

## Prerequisites
You can install Erlang, Elixir, Ruby, and Node using a version manager like [kerl](https://github.com/kerl/kerl), [kiex](https://github.com/taylor/kiex), [rvm](https://github.com/rvm/rvm), or [nvm](https://github.com/creationix/nvm).

# e.g.:

# Install kerl
```
curl -O https://raw.githubusercontent.com/kerl/kerl/master/kerl
chmod a+x kerl
mv kerl /usr/bin
```

# Install erlang
```
kerl build 20.1 20.1
kerl install 20.1 20.1
# follow instructions for running . activate 
```

# Install kiex
```
\curl -sSL https://raw.githubusercontent.com/taylor/kiex/master/install | bash -s
# follow instructions for editing vim ~/.bashrc 
```

# Install elixir
```
kiex install 1.5.1
```

# Install rvm 
```
\curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
```

# Install ruby 
```
rvm install 2.2.1
```

# Install nvm
```
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
```

# Install node
```
nvm install 7.6.0
```

# Create an environment file and test db file (.env and test.secret.exs) using the example files e.g.
```
vim .env.example
vim config/test.secret.exs.example
```

## Build & start the Dashboard API server

  * Install dependencies with `mix deps.get`
  * Compile elixir application with `mix do compile`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Load initial project and cloud data:
    ```
    . .env; mix gitlab_data.load_clouds
    . .env; mix gitlab_data.load_projects
    ```
  * Install Node.js dependencies with `npm install`
  * Install gitlab lib deps `cd lib/gitlab ; bundle install ; cd ../..`
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

## To run using Docker
Set PORT, GITLAB_API, GITLAB_CI_YML, DOCKER_IMAGE, DOCKER_TAG & GITLAB_TOKEN environment variables (can go in .env)

```
export DOCKER_IMAGE=registry.cncf.ci/cncf/cncf_ci_dashboard_backend
export DOCKER_TAG=latest
export GITLAB_TOKEN=secret
docker-compose config
```
Start the Backend Container

```
docker-compose -p Backend up
```

## To run using helm 

Start the Ingress Controller
```
helm install --name nginx-staging stable/nginx-ingress
```

Start Postgres DB
```
helm install --name backend-db stable/postgresql --set postgresUser=backend,postgresPassword=secretbackend,postgresDatabase=backend --set service.type=ClusterIP --set imageTag=9.6
```

Start Backend
```
helm install --name staging-backend cncf/backend --set db.user=backend --set db.password=secretbackend --set db.name=backend --set db.host=backend-db-postgresql --set db.pool=5 --set api=https://gitlab.dev.cncf.ci/api/v4 --set token=secret --set imagePullSecrets=regsecret --set yaml=https://gitlab.cncf.ci/cncf/cross-cloud/raw/ci-stable-v0.1.0/cross-cloud.yml --set ingress.host=mydomian.cncf.ci --set ingress.port=4001 --set image.repository=registry.cncf.ci/cncf/cncf_ci_dashboard_backend --set image.tag=latest
```

Update an existing Backend deployment
```
helm upgrade staging-backend cncf/backend --install --force --set db.user=backend --set db.password=secretbackend --set db.name=backend --set db.host=backend-db-postgresql --set db.pool=5 --set api=https://gitlab.dev.cncf.ci/api/v4 --set token=secret --set imagePullSecrets=regsecret --set yaml=https://gitlab.cncf.ci/cncf/cross-cloud/raw/ci-stable-v0.1.0/cross-cloud.yml --set ingress.host=mydomian.cncf.ci --set ingress.port=4001 --set image.repository=registry.cncf.ci/cncf/cncf_ci_dashboard_backend --set image.tag=latest
```

## To run tests

After setup for running sever above ^^^

  * Setup test DB `MIX_ENV=test mix ecto.migrate`
  * Run tests `. .env; iex -S mix test`

