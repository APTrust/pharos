#FROM ruby:2.4-alpine
FROM  usualoma/ruby-with-therubyracer:2.4.1-alpine
MAINTAINER Christian Dahlhausen <christian@aptrust.org>

# Install dependencies
# - build-base: To ensure certain gems can be compiled
# - nodejs: Compile assets
# - libpq-dev: Communicate with postgres through the postgres gem
# - postgresql-client-9.4: In case you want to talk directly to postgres

RUN apk update -qq && apk upgrade && apk add --no-cache build-base libpq \
    nodejs postgresql-client postgresql-dev ruby-bundler \
    tzdata bash

RUN mkdir /pharos
WORKDIR /pharos

# Set Timezone & Locale
ENV TZ=UTC
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Set Environment
# Environment to be set in .env file and populated by Ansible with correct
# values. Ansible shall start container build and deploy. build script should
# make sure that docker and ansible are installed locally. After build the
# container will be pushed to the server and restarted.
# ENV

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

COPY . $WORKDIR
# - load db schema at first deploy

# - migrate db schema
# - pharos setup (create institutions, roles and users)
# - precompile assets
# - populate db with fixtures if RAILS_ENV=development.

# Provide dummy data to Rails so it can pre-compile assets.
RUN bundle exec rake RAILS_ENV=development DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname SECRET_TOKEN=pickasecuretoken assets:precompile

# Expose rails server port
EXPOSE 3000
EXPOSE 9292

# Cleanup packages we don't need after compilation
RUN apk del ruby-bundler build-base

# Expose a volume so that nginx will be able to read in assets in production.
VOLUME ["$WORKDIR/public"]

# Setup requires DB to be present. setup should be part of deploy?
#RUN rake pharos:setup
#ENTRYPOINT ["$WORKDIR/docker-entrypoint.sh"]
# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["bundle", "exec", "puma", "-b tcp://127.0.0.1:9292"]
