Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
#  config.log_level = :warn
  if ENV['PHAROS_LOG_LEVEL'].present?
    config.log_level = ENV['PHAROS_LOG_LEVEL'].downcase.strip.to_sym
  else
	config.log_level = :debug
  end

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Semantic logger
  # http://rocketjob.github.io/semantic_logger/rails
  #config.colorize_logging = false
  if ENV["DOCKERIZED"] == 'true'
    STDOUT.sync = true
    config.semantic_logger.add_appender(io: STDOUT, level: config.log_level, formatter: config.rails_semantic_logger.format)
  else
    config.semantic_logger.add_appender(file_name: ENV['RAILS_ENV'] + ".log")
  end

  config.rails_semantic_logger.semantic   = false
  config.rails_semantic_logger.started    = true
  config.rails_semantic_logger.processing = true
  config.rails_semantic_logger.rendered   = true
  config.rails_semantic_logger.quiet_assets = true
  config.colorize_logging = false


  if ENV['PHAROS_LOGSERVER'].present?
    #config.logger = GELF::Logger.new( ENV['PHAROS_LOGSERVER'], ENV['PHAROS_LOGSERVER_PORT'], "WAN", { :facility => "PHAROS", :environment => ENV['RAILS_ENV'] })
    config.semantic_logger.add_appender(
  	appender: :graylog,
        url: "udp://#{ENV['PHAROS_LOGSERVER']}:#{ENV['PHAROS_LOGSERVER_PORT']}"
    )
  end


  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # send password reset emails to a file
  config.action_mailer.default_url_options = {
	:host => ENV['PHAROS_HOST'] || 'staging.aptrust.org',
    :protocol => 'https'
  }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
  config.action_mailer.smtp_settings = {
    :address => "email-smtp.us-east-1.amazonaws.com",
    :authentication => :login,
    :enable_starttls_auto => true,
    :port    => 587,
    :user_name => ENV['AWS_SES_USER'],
    :password => ENV['AWS_SES_PWD']
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
  config.show_send_to_dpn_button = false

  config.pharos_receiving_bucket_prefix = 'aptrust.receiving.staging.'
  config.pharos_restore_bucket_prefix = 'aptrust.restore.staging.'
end