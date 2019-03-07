FROM ruby:2.6-alpine3.7
LABEL maintainer="Christian Dahlhausen <christian@aptrust.org>"

# Install dependencies
# - build-base: To ensure certain gems can be compiled
# - nodejs: Compile assets
# - libpq-dev: Communicate with postgres through the postgres gem
# - postgresql-client-9.4: In case you want to talk directly to postgres

RUN apk update -qq && apk upgrade && apk add --no-cache build-base libpq \
    nodejs postgresql-client postgresql-dev python py-requests py-argparse \
    ruby-bundler libstdc++ tzdata bash ruby-dev ruby-nokogiri ruby-bigdecimal \
	libxml2-dev libxslt-dev

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

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --without=["development" "test"] --no-cache

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
