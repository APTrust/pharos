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
#ENV PHAROS_DB_HOST='here'
#ENV PHAROS_DB_NAME='pharos'
#ENV PHAROS_DB_USER='root'
#ENV PHAROS_DB_PASSWORD=''
ENV RAILS_ENV ${ENVIRONMENT:-development}
ENV DEVISE_SECRET_KEY ${DEVISE_SECRET_KEY:-61becfbecdb004668f7a040c857c2d5f030f857212e1941dc89efc064a1065b516057495c6e0d860493d6dd376df154c2ee174f4ad40d14581c39a5240502b6b}
ENV RAILS_SECRET_KEY ${RAILS_SECRET_KEY:-52517cb1d20063c94605ba51bb5c40c4b0e2dc7d4c37bb506f1288f8976a187a4df1fdd820ad88b8382009c84de50f2d53a09d4c17ff2e64f8a99dc4da6a4987}
ENV SECRET_KEY_BASE ${SECRET_KEY_BASE:-52517cb1d20063c94605ba51bb5c40c4b0e2dc7d4c37bb506f1288f8976a187a4df1fdd820ad88b8382009c84de50f2d53a09d4c17ff2e64f8a99dc4da6a4987}
ENV PHAROS_DB_HOST ${PHAROS_DB_HOST:-db}
ENV PHAROS_DB_USER ${PHAROS_DB_USER:-pharos}
ENV PHAROS_DB_PWD ${PHAROS_DB_PWD:-password}
ENV AWS_SES_USER ${AWS_SES_USER:-none}
ENV AWS_SES_PWD ${AWS_SES_PWD:-somesecretsauce}
ENV PHAROS_SYSTEM_USER ${PHAROS_SYSTEM_USER:-system@aptrust.org}
ENV PHAROS_SYSTEM_USER_PWD ${PHAROS_SYSTEM_USER_PWD:-ketchup}
ENV PHAROS_SYSTEM_USER_KEY ${PHAROS_SYSTEM_USER_KEY:-Alexandria}
ENV NSQ_BASE_URL ${NSQ_BASE_URL:-http://nsq:4151}


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
