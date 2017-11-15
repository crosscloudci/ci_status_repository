FROM elixir:1.5-alpine
MAINTAINER "Joshua Darius <sup@joshuadarius.com>"

ADD https://github.com/Yelp/dumb-init/releases/download/v1.1.1/dumb-init_1.1.1_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init
 
WORKDIR /cncf
COPY cncf_ci_dashboard_backend/ /cncf

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix ecto.create && mix ecto.migrate

EXPOSE 4000
CMD ["dumb-init", "mix", "phoenix.server"]
