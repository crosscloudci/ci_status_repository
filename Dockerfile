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

RUN gem install bundler

RUN bundle install --gemfile /backend/lib/gitlab/Gemfile

# based on ^ Gemfile and associated Gemfile.lock TODO: fix having to do this hack
RUN gem install gitlab -v 4.2.0
RUN gem install ttfunk -v 1.6.2.1
RUN gem install prawn -v 2.2.2
RUN gem install json -v 1.8.6
RUN gem install httparty -v 0.15.6
RUN gem install awesome_print -v 1.2.0

EXPOSE 4000

ENTRYPOINT ["/entrypoint.sh"]
