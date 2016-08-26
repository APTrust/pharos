# Pharos

[![Code Climate](https://codeclimate.com/github/APTrust/pharos.png)](https://codeclimate.com/github/APTrust/pharos.png?branch=develop)
[![Dependency Status](https://gemnasium.com/badges/github.com/APTrust/pharos.svg)](https://gemnasium.com/github.com/APTrust/pharos)

Build Status | Continuous Integration | Code Coverate
--- | --- | ---
Production | [![Build Status (Master)](https://travis-ci.org/APTrust/pharos.png?branch=master)](https://travis-ci.org/APTrust/pharos) | [![Coverage Status](https://coveralls.io/repos/github/APTrust/pharos/badge.svg?branch=master)](https://coveralls.io/github/APTrust/pharos?branch=master)
Development | [![Build Status (Development)](https://travis-ci.org/APTrust/pharos.png?branch=develop)](https://travis-ci.org/APTrust/pharos) | [![Coverage Status](https://coveralls.io/repos/github/APTrust/pharos/badge.svg?branch=develop)](https://coveralls.io/github/APTrust/pharos?branch=develop)

## APTrust Admin Console

This application uses ActiveRecord to interact with a SQL database that is backed, down the line, by Fedora.

### Requirements

See 'fluctus/Gemfile' for a full list of current dependencies.

Overall Fluctus targets the following versions or later

* Ruby >= 2.2.0
* Rails >= 4.2.7

### Additional Configuration

We use the figaro gem for additional application configuration through 'fluctus/config/application.yml' which is added
to the .gitignore file by default.  You will need to copy 'fluctus/config/application.yml.local' to
'fluctus/config/application.yml' and setup values as appropriate.

Use the ``` rake secret ``` command to generate secret keys for rails and devise.  Paste those keys into the 'fluctus/config/application.yml' file.


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
gf.add_event(FactoryGirl.attributes_for(:premis_events_fixity_check_fail))
gf.save
````
## Statistics sampling
To create a sample run the script like so:
```
$ RAILS_ENV=production ./script/sample_uploads
```
You probably want to put this in a cron job so it can be run regularly


## Heroku Instructions

Note, section dropped as previous pharos app was deleted.  Intend to rebuild this.

# Notes on Queries

Most quieries are best carried out through the solr index in the formate below.

The format is as follows::

  <Class>.where(rails cased datastream name: <value>)

So as an example, if you were to query for "APTrust" in the name field of the
Institution model you would search as follows::

  ins = Institution.where(name: "APTrust")