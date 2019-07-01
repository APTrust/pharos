source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.1.20'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0.0'
# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'chart-js-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9.1'
gem 'pg', '1.1.4' # Necessary for talking to our RDS instance
gem 'pundit'
gem 'figaro'
gem 'devise', '4.6.2'
gem 'rake'
gem 'email_validator'

# Used to generate PDFs for reports
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
# Used to create or edit google sheets
gem 'google_drive'

gem 'simple_form', '~> 4.1.0'
gem 'phony_rails'
gem 'inherited_resources', '1.10.0'
gem 'uuidtools'
gem 'kaminari'
gem 'sassc-rails'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'browser-timezone-rails'
gem 'activerecord-nulldb-adapter'
gem 'puma'

group :demo, :production do
  # Graylog logging gems
  gem 'rails_semantic_logger'
  gem 'gelf'
  gem 'awesome_print'
end

group :development do
  gem 'meta_request', '=0.7.0'
  gem 'better_errors'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.7.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'rb-readline'
end

group :test, :development do
  gem 'capybara', '3.25.0'
  gem 'shoulda-matchers', '~> 4.1.0'
  gem 'coveralls', '0.8.23', require: false
  gem 'rails-controller-testing'
end

group :development, :test, :demo, :production, :integration do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 3.8.2'
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
end
