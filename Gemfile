source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.2.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0.0'
# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'chart-js-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.10.1'
gem 'pg', '1.2.3' # Necessary for talking to our RDS instance
gem 'pundit'
# gem 'figaro'
gem 'devise', '4.7.3'
gem 'devise-security'
gem 'devise-two-factor'
gem 'dotenv-rails'
gem 'aws-sdk-sns'
gem 'devise-authy'
gem 'rake', '13.0.1'
gem 'email_validator'
gem 'phonelib'

# Used to generate PDFs for reports
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
# Generate zip files
gem 'rubyzip'
# Used to create or edit google sheets
gem 'google_drive'

gem 'simple_form', '~> 5.0.3'
gem 'phony_rails'
gem 'inherited_resources', '1.11.0'
gem 'uuidtools'
gem 'kaminari'
gem 'sassc-rails'
gem 'sassc', '2.4.0'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'browser-timezone-rails'
gem 'sprockets', '~> 3.7.2'

gem 'activerecord-nulldb-adapter'
gem 'puma', '4.3.5'

group :demo, :production, :staging do
  # Graylog logging gems
  gem 'rails_semantic_logger'
  gem 'gelf'
  gem 'awesome_print'
end

group :development do
  gem 'meta_request', '0.7.2'
  gem 'better_errors'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.7.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'rb-readline'
end

group :test, :development do
  gem 'capybara', '3.34.0'
  gem 'shoulda-matchers', '~> 4.4.1'
  gem 'coveralls', '0.8.23', require: false
  gem 'rails-controller-testing'
  gem 'mimemagic'
end

group :development, :test, :staging, :demo, :production, :integration, :docker_integration do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 4.0.1'
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
end
