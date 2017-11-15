# FROM buildpack-deps:stretch
FROM bitwalker/alpine-elixir-phoenix:latest
MAINTAINER "Denver Williams <denver@debian.nz>"

COPY . /backend

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

COPY Dockerfiles/dev.secret.exs /backend/config/dev.secret.exs

WORKDIR /backend

RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get \
    && npm install

EXPOSE 4000

EXPOSE 4009

ENTRYPOINT ["/entrypoint.sh"]
