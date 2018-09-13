# Elixir Debugging

# Run the setup shell before any of these commands
```
. setup.sh
```

# To start a dev server (especially on a shared box)
```
. .env; PORT=YOURPORTNUMBERSETINENV iex -S mix phoenix.server
```

# To run the tests:
```
. .env; iex -S mix test --only wip 
```

# To run the tests continuously:
```
. .env; iex -S mix test.watch --only wip
```

# To run only the wip (work in progress) tests
  * Add @wip before declaring a test
  * Run:
  ```
  . .env; iex -S mix test --only wip 
  ```

# To Debug:
```
require IEx; IEx.pry
```

# To start Iex
```
. .env; iex -S mix
```

# To query the database in the debugger or Iex
```
import Ecto.Query
alias CncfDashboardApi.Repo
```
# Query examples
```
Repo.all(CncfDashboardApi.Projects)
CncfDashboardApi.Repo.all(from pj in CncfDashboardApi.PipelineJobs, where: pj.pipeline_id == 6851)
Repo.all ( from user in User, where: like(user.username, "%vulk%")) 
```

# Usefule file text search
```
grep --exclude-dir={node_modules,_build,priv,deps,graphdoc} --exclude=*.sql -rnw '.' -e '.*YOURSEARCHTEXT.*'
```
