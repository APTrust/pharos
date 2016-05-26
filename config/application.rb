require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pharos
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end


  #GLOBALS
  PHAROS_STATUSES = {
      'pend' => 'Pending',
      'start' => 'Started',
      'success' => 'Success',
      'fail' => 'Failed',
      'cancel' => 'Cancelled'
  }

  PHAROS_STAGES = {
      'requested' => 'Requested',
      'receive' => 'Receive',
      'fetch' => 'Fetch',
      'unpack' => 'Unpack',
      'validate' => 'Validate',
      'store' => 'Store',
      'record' => 'Record',
      'clean' => 'Cleanup',
      'resolve' => 'Resolve'
  }

  PHAROS_ACTIONS = {
      'ingest' => 'Ingest',
      'fixity' => 'Fixity Check',
      'restore' => 'Restore',
      'delete' => 'Delete',
      'dpn' => 'DPN'
  }

  DPN_STATUS = false

  APTRUST_NAME = 'APTrust'
  APTRUST_ID = 'aptrust.org'
end
