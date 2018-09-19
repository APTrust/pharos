# Pharos

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/5d37b48c4c5547cca0c9c61a5887f589)](https://www.codacy.com/app/cdahlhausen/pharos?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=APTrust/pharos&amp;utm_campaign=Badge_Grade)
[![Code Climate](https://codeclimate.com/github/APTrust/pharos.png)](https://codeclimate.com/github/APTrust/pharos.png?branch=develop)
[![Dependency Status](https://gemnasium.com/badges/github.com/APTrust/pharos.svg)](https://gemnasium.com/github.com/APTrust/pharos)

Build Status | Continuous Integration | Code Coverage
--- | --- | ---
develop | [![Build Status (Development)](https://travis-ci.org/APTrust/pharos.png?branch=develop)](https://travis-ci.org/APTrust/pharos) | [![Coverage Status](https://coveralls.io/repos/github/APTrust/pharos/badge.svg?branch=develop)](https://coveralls.io/github/APTrust/pharos?branch=develop)

## APTrust Admin Console

This application uses ActiveRecord to interact with a SQL database.

### Requirements

See 'Gemfile' for a full list of current dependencies.

Overall Pharos targets the following versions or later

* Ruby >= 2.2.0
* Rails >= 4.2.7

Installing the Postgres gem on Mac with Postgres.app:

`gem install pg -v 1.1.3 -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config`

If you have only one version of Postgres installed, substitute version number (e.g. 9.5 or 10.0) for 'latest' in the path above.

### Additional Configuration

We use the figaro gem for additional application configuration through 'pharos/config/application.yml' which is added
to the .gitignore file by default.  You will need to copy 'pharos/config/application.yml.local' to
'pharos/config/application.yml' and setup values as appropriate.

Use the ``` rake secret ``` command to generate secret keys for rails and devise.  Paste those keys into the 'pharos/config/application.yml' file.


* Setup APTrust Institution object and Roles

````

# create the db schema
rake db:migrate

# rake task to setup initial insitutions, roles and a default aptrust_admin user.
rake pharos:setup
````

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
## Statistics sampling
To create a sample run the script like so:
```
$ RAILS_ENV=production ./script/sample_uploads
```
You probably want to put this in a cron job so it can be run regularly
