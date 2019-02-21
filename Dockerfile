FROM ruby:2.6-alpine3.7
LABEL maintainer="Christian Dahlhausen <christian@aptrust.org>"

# Install dependencies
# - build-base: To ensure certain gems can be compiled
# - nodejs: Compile assets
# - libpq-dev: Communicate with postgres through the postgres gem
# - postgresql-client-9.4: In case you want to talk directly to postgres

RUN apk update -qq && apk upgrade && apk add --no-cache build-base libpq \
    nodejs postgresql-client postgresql-dev python py-requests py-argparse \
    ruby-bundler libstdc++ tzdata bash ruby-dev ruby-nokogiri ruby-bigdecimal libxml2-dev libxslt-dev

RUN addgroup -S somegroup -g 1000 && adduser -S -G somegroup somebody -u 1000

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
#ENV PHAROS_DB_PWD=''
ENV RAILS_ENV=${RAILS_ENV:-development}
ENV DEVISE_SECRET_KEY=${DEVISE_SECRET_KEY:-61becfbecdb004668f7a040c857c2d5f030f857212e1941dc89efc064a1065b516057495c6e0d860493d6dd376df154c2ee174f4ad40d14581c39a5240502b6b}
ENV RAILS_SECRET_KEY=${RAILS_SECRET_KEY:-52517cb1d20063c94605ba51bb5c40c4b0e2dc7d4c37bb506f1288f8976a187a4df1fdd820ad88b8382009c84de50f2d53a09d4c17ff2e64f8a99dc4da6a4987}
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE:-52517cb1d20063c94605ba51bb5c40c4b0e2dc7d4c37bb506f1288f8976a187a4df1fdd820ad88b8382009c84de50f2d53a09d4c17ff2e64f8a99dc4da6a4987}
ENV TWO_FACTOR_KEY=${TWO_FACTOR_KEY:-bb9043530987217fbe7885de7d46235db6ac1bddb1fd6a9dc9172538697a988c9148a1d652fa0b3ad09ea0938bc3db68b45a165eb2c71891d952305bd2495325}
ENV PHAROS_DB_HOST=${PHAROS_DB_HOST:-db}
ENV PHAROS_DB_USER=${PHAROS_DB_USER:-pharos}
ENV PHAROS_DB_PWD=${PHAROS_DB_PWD:-password}
ENV AWS_SES_USER=${AWS_SES_USER:-none}
ENV AWS_SES_PWD=${AWS_SES_PWD:-somesecretsauce}
ENV PHAROS_RELEASE=${REVISION:-latest}
ENV PHAROS_SYSTEM_USER=${PHAROS_SYSTEM_USER:-system@aptrust.org}
ENV PHAROS_SYSTEM_USER_PWD=${PHAROS_SYSTEM_USER_PWD:-ketchup}
ENV PHAROS_SYSTEM_USER_KEY=${PHAROS_SYSTEM_USER_KEY:-Alexandria}
ENV NSQ_BASE_URL=${NSQ_BASE_URL:-http://nsq:4151}

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

COPY . $WORKDIR

# - load db schema at first deploy
# - migrate db schema
# - pharos setup (create institutions, roles and users)
# --> These should be part of a build script. The only purpose of this image is
# to provide the rails environment and app. It assumes an external db (per env)

# Provide dummy data to Rails so it can pre-compile assets.
RUN bundle exec rake RAILS_ENV=production DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname SECRET_TOKEN=pickasecuretoken assets:precompile

# Expose rails server port
EXPOSE 9292

# Cleanup packages we don't need after compilation
RUN apk del build-base postgresql-dev postgresql-client libxml2-dev libxslt-dev \
            ruby-bundler ruby-dev ruby-bigdecimal && \
    rm -rf /usr/lib/ruby/gems/*/cache/* \
           /usr/local/bundle/cache/* \
           /var/cache/apk/* \
           /tmp/* \
           /var/tmp/*

# Expose a volume so that nginx will be able to read in assets in production.
VOLUME ["$WORKDIR/public"]

RUN chown -R somebody:somegroup /pharos
USER somebody

CMD ["bundle", "exec", "puma", "-p9292"]
