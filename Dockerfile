FROM ruby:slim

MAINTAINER Christian Dahlhausen <christian@aptrust.org>

# Install dependencies
# - build-essential: To ensure certain gems can be compiled
# - nodejs: Compile assets
# - libpq-dev: Communicate with postgres through the postgres gem
# - postgresql-client-9.4: In case you want to talk directly to postgres
RUN apt-get update && apt-get install -qq -y git build-essential libpq-dev nodejs \
            bundler postgresql-client libpq5 libpqxx-dev sqlite3 libsqlite3-dev\
            --fix-missing --no-install-recommends

# Clean APT cache to keep image lean
RUN rm -rf /var/cache/apt/*

# Create Pharos workdir
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

# install bundler
RUN gem install bundler --no-ri --no-rdoc

ADD . /pharos
RUN export PHAROS_RELEASE=$(git rev-parse --short HEAD)

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install

# Provide dummy data to Rails so it can pre-compile assets.
RUN RAILS_ENV=development DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname SECRET_TOKEN=pickasecuretoken rake assets:precompile

# - load db schema at first deploy
#RUN RAILS_ENV=development rake db:schema:load
# - migrate db schema
RUN RAILS_ENV=development rake db:migrate
# - pharos setup (create institutions, roles and users)
RUN RAILS_ENV=development rake pharos:setup
# - populate db with fixtures if RAILS_ENV=development.

# Expose rails server port
# TODO: Add standalone passenger later.
EXPOSE 3000

# Expose a volume so that nginx will be able to read in assets in production.
VOLUME ["$WORKDIR/public"]

# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
