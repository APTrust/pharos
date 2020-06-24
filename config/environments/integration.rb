#
# Configuration for running integration tests between APTrust's
# Go services and Pharos.
#

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Reload classes when they change?
  # When running integration tests, this should be false, because
  # it makes Pharos very slow. When running interactive tests and
  # fiddling with Rails code, this should be true, so it reloads
  # code whenever you make a change.
  config.cache_classes = true

  # Eager load code on boot.
  config.eager_load = true


  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Eager load code on boot.
  config.eager_load = true

  # Configure static file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Log debug messages, because we're testing.
  config.colorize_logging = false
  config.log_level = :debug

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.pharos_receiving_bucket_prefix = 'aptrust.receiving.integration.'
  config.pharos_restore_bucket_prefix = 'aptrust.restore.integration.'
end
