# Pharos

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/5d37b48c4c5547cca0c9c61a5887f589)](https://www.codacy.com/app/cdahlhausen/pharos?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=APTrust/pharos&amp;utm_campaign=Badge_Grade)
[![Code Climate](https://codeclimate.com/github/APTrust/pharos.png)](https://codeclimate.com/github/APTrust/pharos.png?branch=develop)

Build Status | Continuous Integration | Code Coverage
--- | --- | ---
develop | [![Build Status (Development)](https://travis-ci.org/APTrust/pharos.png?branch=develop)](https://travis-ci.org/APTrust/pharos) | [![Coverage Status](https://coveralls.io/repos/github/APTrust/pharos/badge.svg?branch=develop)](https://coveralls.io/github/APTrust/pharos?branch=develop)

### Requirements
Since mid 2019 the Pharos app has been containerized. You may use the Baremetal or Docker version for development.

#### Docker Version Requirements
* [Docker Desktop](https://hub.docker.com/search/?type=edition&offering=community)
* [Make](Makefile)

#### Baremetal Version Requirements
* [Bundler](https://bundler.io)
* [Ruby >= 2.5.0](https://www.ruby-lang.org/en/)
* [Rails >= 5.2.3](https://rubyonrails.org/)
* [Postgres](https://postgresapp.com/)

Installing the Postgres gem on Mac with Postgres.app:
```gem install pg -v 1.2.0 -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config```

### Configuration

We use [dotenv](https://github.com/bkeepers/dotenv) for application
configuration. See `.env` file in this repository for configuration parameters
with default/development values. This file is updated by deployment according to
it's environment.

### Development Credentials

After running `rake pharos:setup` or `make build` and `make dev`
you can log in with
- Email: ops@aptrust.org
- Password: password123

### Docker Development Quick-Start

Once you have the Docker suite installed you may run `make` and see list of make targets you can run with ``` make <target>```.
To get started run:
1.  `make build` This builds containers based on the current git version of the repository. If you get an error about "docker login," run `docker login registry.gitlab.com`
2.  `make dev` will start all containers (Postgres, Pharos, Nginx) and populate the database with seed data to get started.

3. You may now open a web browser and open `http://localhost:9292` and log-in with [development credentials](#development-credentials)

| Target | Description |
| ----- | ------|
| build    |  Build the Pharos container from current repo. Make sure to commit all changes beforehand |
| build-nc | Build the Pharos container from scratch, no cached layers.|
| clean | Clean the generated/compiled files |
| dev | Run Pharos for development on localhost|
| devclean | Stop and remove running Docker containers |
| devstop | Stop running Docker containers. Can pick up dev later |
| down | Stop containers for Pharos, Postgresql, Nginx. For local development. |
| dtest | Run Pharos spec tests |
| help  | This help.|
| integration  | Runs Pharos container with fixtures for integration tests. |
| integration_clean  | Stops and removes Pharos integration containers. |
| push | Push the Docker image up to the registry |
| release | Make a release by building and publishing the `{version}` as `latest` tagged containers to Gitlab |
| revision | Show me the git hash|
| run | Just run Pharos in foreground |
| runcmd | Start Pharos container, run command and exit.|
| runconsole | Run Rails Console |
| runshell | Run Pharos container with interactive shell |
| test-ci | Run Pharos spec tests in CI |
| up | Start containers in background for Pharos, Postgresql, Nginx. For local development. |

#### Common Docker tasks
- Enter running environment in demo/prod
	- cd /srv/docker/pharos
	- sudo docker-compose exec pharos bash
- Run a one-off command within the environment
	- cd /srv/docker/pharos
	- `make runcmd <somecommand>`


### Baremetal Development Quick-Start

1. Make sure the [requirements are met](#baremetal-version-requirements)
2. Install dependencies: `bundle install`
3. Create db schema: `rake db:migrate`
4. Initial setup of seed data: `rake pharos:setup`
5. Start appserver `bundle exec puma`

------


### Setting up Test Data

* Populating stub data for testing.

There is a simple rake task to setup dummy data in SQL. by default this rake task sets up 16 or so institutions
(one for each partner), about 5 fake users in each institution, 3-10 Intellectual Objects and 3-30 Generic Files for
each Intellectual Object with a handful of Premis Events for each.

rake pharos:populate_db

Note the Generic File Object pid that will be output so you can use that to load the proper object in the web
interface for testing.

*  Adding an event failure

A simple factory will allow you to add a failed version of any of the current premis events just by
using the factory name and adding _fail at the end.  So to add some fake data for a failed event for
testing you could do the following in code or at command line.

````
#Start by getting the object you want to add the failed event to.
gf = GenericFile.first

#Then add the event as attributes
gf.add_event(FactoryBot.attributes_for(:premis_events_fixity_check_fail))
gf.save
````

--------

## API Documentation

Swagger docs at https://aptrust.github.io/pharos/
