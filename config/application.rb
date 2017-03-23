require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pharos
  class Application < Rails::Application
    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    Faker::Config.locale = 'en-US'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    VERSION = "1.0"

    config.i18n.enforce_available_locales = true

    #config.serve_static_assets = true

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
        'resolve' => 'Resolve',
        'package' => 'Package'
    }

    PHAROS_ACTIONS = {
        'ingest' => 'Ingest',
        'fixity' => 'Fixity Check',
        'restore' => 'Restore',
        'delete' => 'Delete',
        'dpn' => 'DPN'
    }

    PHAROS_EVENT_TYPES = {
	      'access_assignment' => 'access assignment',
        'capture' => 'capture',
        'compress' => 'compression',
        'create' => 'creation',
        'deaccess' => 'deaccession',
        'decompress' => 'decompression',
        'decrypt' => 'decryption',
        'delete' => 'deletion',
        'digest_calc' => 'message digest calculation',
        'fixity' => 'fixity check',
        'ident_assignment' => 'identifier assignment',
        'ingest' => 'ingestion',
        'migrate' => 'migration',
        'normal' => 'normalization',
        'replicate' => 'replication',
        'sig_validate' => 'digital signature validation',
        'validate' => 'validation',
        'virus_check' => 'virus check'
    }

    DPN_TASKS = %w(sync ingest replication restore fixity)

    DPN_STATUS = false
    DPN_SIZE_LIMIT = 268435456000 # 250GB

    APTRUST_NAME = 'APTrust'
    APTRUST_ID = 'aptrust.org'

    if Rails.env.production?
      NSQ_BASE_URL = 'http://prod-services.aptrust.org:4151'
    elsif Rails.env.development?
      NSQ_BASE_URL = 'http://demo-services.aptrust.org:4151'
    end

  end
end

