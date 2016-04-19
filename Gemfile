source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '1.3.10'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# as an authorization replacement for CanCan
gem 'pundit'
gem 'figaro'
gem 'devise', '3.3.0'
gem 'rake'
gem 'rename'

#gem 'omniauth-google-oauth2'
gem 'simple_form', '~> 3.0.2'
#gem "hydra-role-management", "~> 0.1.0"
gem 'phony_rails'
gem 'inherited_resources'
gem 'uuidtools'

gem 'kaminari'
gem 'minitest'

# S3 connector
gem 'aws-sdk-core'

group :development do
  gem 'meta_request'
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :development, :test, :demo do
  gem "jettywrapper"
end

group :development, :test, :demo, :production do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'faker', github: 'stympy/faker'
  gem 'quiet_assets'
  gem 'rspec-rails', '~> 3.0.0'
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
end

group :test do
  gem 'capybara', '2.3.0'
  gem 'shoulda-matchers'
  gem 'coveralls', require: false
end

group :production do
  gem 'pg' #Necessary for heroku
  gem "rails_12factor" # Necessary for heroku
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

