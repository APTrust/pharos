# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'capybara/rails'
require 'capybara/rspec'
require 'coveralls'
require 'simplecov'

# push test code to remote and produce locally.
Coveralls.wear!
SimpleCov.start 'rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

# Enable capybara to login and logout users
include Warden::Test::Helpers
Warden.test_mode!

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Capybara.default_driver = :selenium

RSpec.configure do |config|

  # Add all pharos roles before testing.
  config.before(:all) do
    %w(admin institutional_admin institutional_user).each do |role|
      Role.where(name: role).first_or_create
    end

    # Create our default institution
    # FactoryGirl.create(:aptrust)
  end

  config.after(:all) do
    GenericFile.destroy_all
    IntellectualObject.destroy_all
    Institution.destroy_all
  end

  config.color = true

  #config.include(EmailSpec::Helpers)
  #config.include(EmailSpec::Matchers)

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'defined'

  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  #For devise testing
  config.include Devise::Test::ControllerHelpers, :type => :controller

  # config.backtrace_exclusion_patterns = Array.new
end