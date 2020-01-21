FROM crosscloudci/backend-deps:latest

MAINTAINER "Denver Williams <denver@debian.nz>"

COPY . /backend
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

COPY Dockerfiles/dev.secret.exs /backend/config/dev.secret.exs

WORKDIR /backend

RUN mix local.hex --force &&  \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile

RUN gem install bundler

RUN bundle install --gemfile /backend/lib/gitlab/Gemfile
RUN gem install gitlab
RUN gem install prawn
RUN gem install json
RUN gem install httparty
RUN gem install awesome_print

EXPOSE 4000

ENTRYPOINT ["/entrypoint.sh"]
