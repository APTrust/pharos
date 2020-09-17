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

	VERSION = "2.5"

    config.i18n.enforce_available_locales = true

	#config.public_file_server.enable = false
    config.assets.version = '1.0'
	config.assets.precompile += %w(.svg)

    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'dev_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end

    #GLOBALS
    PHAROS_STATUSES = {
        'pend' => 'Pending',
        'start' => 'Started',
        'success' => 'Success',
        'fail' => 'Failed',
        'cancel' => 'Cancelled',
        'suspended' => 'Suspended'
    }

    PHAROS_STAGES = {
        'requested' => 'Requested',
        'receive' => 'Receive',
        'fetch' => 'Fetch',
        'format_identification' => 'Format Identification',
        'unpack' => 'Unpack',
        'validate' => 'Validate',
        'reingest_check' => 'Reingest Check',
        'copy_to_staging' => 'Copy To Staging',
        'store' => 'Store',
        'storage_validation' => 'Storage Validation',
        'record' => 'Record',
        'cleanup' => 'Cleanup',
        'resolve' => 'Resolve',
        'package' => 'Package',
        'restoring' => 'Restoring',
        'available_in_s3' => 'Available in S3'
    }

    # Map NSQ topics to stage. Yes, receive and fetch are the same topic.
    # This is a mess because keys in this hash have to match VALUES
    # in PHAROS_STAGES hash above.
    # TODO: Bundle Stage names, stage topic names, and stage default messages
    # into one class?
    NSQ_TOPIC_FOR_STAGE = {
        'Requested' => nil,
        'Receive' => 'ingest01_prefetch',
        'Fetch' => 'ingest01_prefetch',
        'Format Identification' => 'ingest05_format_identification',
        'Unpack' => nil, # No longer used
        'Validate' => 'ingest02_bag_validation',
        'Reingest Check' => 'ingest03_reingest_check',
        'Copy To Ctaging' => 'ingest04_staging',
        'Store' => 'ingest06_storage',
        'Storage Validation' => 'ingest07_storage_validation',
        'Record' => 'ingest08_record',
        'Cleanup' => 'ingest09_cleanup',
        'Resolve' => nil,
        'Package' => nil, # TBD when restoration services are ready
        'Restoring' => nil,
        'Available in S3' => nil
    }

    PHAROS_ACTIONS = {
        'ingest' => 'Ingest',
        'fixity' => 'Fixity Check',
        'restore' => 'Restore',
		'glacier_restore' => 'Glacier Restore',
        'delete' => 'Delete'
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

    # Be sure to preserve case on these.
    # These constants are also defined in preservation services.
    PHAROS_STORAGE_OPTIONS = %w(Standard Glacier-OH Glacier-VA Glacier-OR Glacier-Deep-VA Glacier-Deep-OH Glacier-Deep-OR Wasabi-OR Wasabi-VA)

    APTRUST_NAME = 'APTrust'
    APTRUST_ID = 'aptrust.org'

    VALID_DOMAINS = %w(com edu org museum)

    # What's this? List of all params allowed throughout entire app?
    # If so, it's an antipattern and a security risk.
    PARAMS_HASH = [
      :access,
      :alt_identifier,
      :alt_identifier_like,
      :api,
      :authenticity_token,
      :bag_date,
      :bag_group_identifier,
      :bag_group_identifier,
      :bag_group_identifier_like,
      :bag_name,
      :bag_name_like,
      :completed_after,
      :completed_before,
      :confirmation_token,
      :created_after,
      :created_at,
      :created_before,
      :description,
      :description_like,
      :etag,
      :etag_contains,
      :etag_like,
      :event_identifier,
      :event_type,
      :file_association,
      :file_format,
      :file_identifier,
      :file_identifier_contains,
      :file_identifier_like,
      :format,
      :generic_file_id,
      :identifier,
      :identifier_like,
      :include_checksums,
      :include_events,
      :include_relations,
      :institution,
      :institution_id,
      :institution_identifier,
      :intellectual_object_id,
      :is_completed,
      :is_not_completed,
      :item_action,
      :member_institution_id,
      :method,
      :name,
      :name_contains,
      :name_exact,
      :needs_admin_review,
      :node,
      :node_1,
      :node_2,
      :node_3,
      :node_empty,
      :node_not_empty,
      :not_checked_since,
      :object_association,
      :object_identifier,
      :object_identifier_contains,
      :object_identifier_like,
      :object_type,
      :outcome,
      :page,
      :per_page,
      :pid,
      :pid_empty,
      :pid_not_empty,
      :q,
      :queued,
      :queued_after,
      :queued_before,
      :remote_node,
      :requesting_user_id,
      :retry,
      :search_field,
      :sort,
      :stage,
      :state,
      :status,
      :storage_option,
      :task,
      :type,
      :type,
      :updated_after,
      :updated_before,
      :updated_since,
      :uri,
      :utf8,
      :v2
    ]

	NSQ_BASE_URL = ENV['NSQ_BASE_URL']
  end
end
