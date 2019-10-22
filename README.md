# Pharos

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/5d37b48c4c5547cca0c9c61a5887f589)](https://www.codacy.com/app/cdahlhausen/pharos?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=APTrust/pharos&amp;utm_campaign=Badge_Grade)
[![Code Climate](https://codeclimate.com/github/APTrust/pharos.png)](https://codeclimate.com/github/APTrust/pharos.png?branch=develop)

Build Status | Continuous Integration | Code Coverage
--- | --- | ---
develop | [![Build Status (Development)](https://travis-ci.org/APTrust/pharos.png?branch=develop)](https://travis-ci.org/APTrust/pharos) | [![Coverage Status](https://coveralls.io/repos/github/APTrust/pharos/badge.svg?branch=develop)](https://coveralls.io/github/APTrust/pharos?branch=develop)

### Requirements

Since mid 2019 the Pharos app has been containerized. You may use the Baremetal
or Docker version for development. In this case you will need

#### Docker Version Requirements
* [Docker Desktop](https://hub.docker.com/search/?type=edition&offering=community)
* [Make](Makefile)

#### Baremetal Version Requirements
* [Bundler](https://bundler.io)
* [Ruby >= 2.5.0](https://www.ruby-lang.org/en/)
* [Rails >= 5.2.3](https://rubyonrails.org/)
* [Postgres](https://postgresapp.com/)

Installing the Postgres gem on Mac with Postgres.app:
```gem install pg -v 1.1.4 -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin pg_config```

### Configuration

We use [dotenv](https://github.com/bkeepers/dotenv) for application
configuration. See `.env` file in this repository for configuration parameters
with default/development values. This file is updated by deployment according to
it's environment.

### Development credentials

After running `rake pharos:setup` or `make build` and `make dev`
you can log in wiht
Email: ops@aptrust.org
Password: 'password123'

### Docker Develeopment Quick Start

Once you have the Docker suite installed you may run `make build`. This builds
containers based of the current git version of the repository.
`make dev` will start all containers (Postgres, Pharos, Nginx) and populate the
database with seed data to get started.
You may now open a web browser and open `http://localhost:9292` and log-in with
development credentials

------
* Setup APTrust Institution object and Roles

```shell

# create the db schema
rake db:migrate

# rake task to setup initial insitutions, roles and a default aptrust_admin user.
rake pharos:setup
```

The default admin user that is being setup as follows:
    name= "APTrustAdmin"
    email= "ops@aptrust.org"
    phone_number="4341234567"
    password="password"

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
# Start by getting the object you want to add the failed event to.
gf = GenericFile.first

# Then add the event as attributes
gf.add_event(FactoryBot.attributes_for(:premis_events_fixity_check_fail))
gf.save
````
