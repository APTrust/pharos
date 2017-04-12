source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.0.2'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '1.3.13'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 3.0.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2.1'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.6.3'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.2', group: :doc

gem 'pundit'
gem 'figaro'
gem 'devise', '4.2.1'
gem 'rake'
gem 'valid_email'
gem 'therubyracer'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

#gem 'omniauth-google-oauth2'
gem 'simple_form', '~> 3.4.0'
gem 'phony_rails'
gem 'inherited_resources', '1.7.1'
gem 'uuidtools'

gem 'kaminari'
gem 'bootstrap-sass', '~> 3.3.7'

# S3 connector
gem 'aws-sdk-core'

group :development do
  gem 'meta_request'
  gem 'better_errors'
  #gem 'binding_of_caller'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.5.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :test do
  gem 'capybara', '2.13.0'
  gem 'shoulda-matchers', '~> 3.1.1'
  gem 'coveralls', '0.8.20', require: false
end

group :production do
  gem 'pg' # Necessary for talking to our RDS instance
end

group :development, :test, :demo, :production, :integration do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 3.5'
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
end
