FROM crosscloudci/backend-deps:prod

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

RUN npm install
RUN gem install bundler

RUN bundle install --gemfile /backend/lib/gitlab/Gemfile

EXPOSE 4000

ENTRYPOINT ["/entrypoint.sh"]
