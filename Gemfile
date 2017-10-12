source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.1.4'
gem 'rails-controller-testing'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '1.3.13'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 3.0.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2.2'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.2', group: :doc

gem 'pundit'
gem 'figaro'
gem 'devise', '4.3'
gem 'rake'
gem 'email_validator'
gem 'therubyracer'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

#gem 'omniauth-google-oauth2'
gem 'simple_form', '~> 3.5.0'
gem 'phony_rails'
gem 'inherited_resources', '1.7.2'
gem 'uuidtools'

gem 'kaminari'
gem 'bootstrap-sass', '~> 3.3.7'

# This gem isn't required directly but is required in dependencies and needs specific updating due to a security warning
gem 'mail', '>= 2.6.6.rc1'

# S3 connector
#gem 'aws-sdk-core'

group :development do
  gem 'meta_request', '=0.4.3'
  gem 'better_errors'
  #gem 'binding_of_caller'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.5.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :test do
  gem 'capybara', '2.15.4'
  gem 'shoulda-matchers', '~> 3.1.2'
  gem 'coveralls', '0.8.21', require: false
end

group :production, :integration do
  gem 'pg' # Necessary for talking to our RDS instance
end

group :development, :test, :demo, :production, :integration do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 3.6.1'
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
end
