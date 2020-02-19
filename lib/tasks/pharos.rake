desc 'Run specs'
RSpec::Core::RakeTask.new(:rspec => 'test:prepare') { |t| t.rspec_opts = ['--colour', '--profile 20'] }

namespace :pharos do

  # DPN member UUIDs are at
  # https://docs.google.com/spreadsheets/d/1-WFK0me8dM2jETlUkI7wpmRFMOgHC5LhyYk6hgHOfIA/
  partner_list = [
      ['APTrust', 'apt', 'aptrust.org', nil],
      ['Columbia University', 'cul', 'columbia.edu', 'ed73acd4-93e9-4196-a1ba-7fc8031b5f0b'],
      ['Indiana University Bloomington', 'iub', 'indiana.edu', '77abdcc5-6d50-441b-8fd7-8085ceba5f05'],
      ['Johns Hopkins University', 'jhu', 'jhu.edu', '0ab32901-5377-4928-898c-f4c5e2cde8e1'],
      ['North Carolina State University', 'ncsu', 'ncsu.edu', 'd3432b4f-9f82-4206-a086-89bff5c5bd1e'],
      ['Pennsylvania State University', 'pst', 'psu.edu', 'cf153594-6c22-4b59-a12e-420e0ae5280f'],
      ['Syracuse University', 'syr', 'syr.edu', 'd5e231ad-cf1f-4499-9afe-7045f1254eaa'],
      ['Test University','test', 'test.edu', 'fe908327-3635-43c2-9ca6-849485febcf3'],
      ['University of Chicago', 'uchi', 'uchicago.edu', nil],
      ['University of Cincinnati', 'ucin', 'uc.edu', nil],
      ['University of Connecticut', 'uconn', 'uconn.edu', nil],
      ['University of Maryland', 'mdu', 'umd.edu', 'a905b4da-cb04-43b9-8e23-ee43e02b23df'],
      ['University of Miami', 'um', 'miami.edu', '41d34f47-ab83-4fa3-a40d-85465bc5fd14'],
      ['University of Michigan', 'umich', 'umich.edu', '7277cbab-d539-4a81-ac1e-70cefc28fb2e'],
      ['University of North Carolina at Chapel Hill', 'unc', 'unc.edu', 'cdd177a9-fe6b-4b75-9960-d808d1fb5570'],
      ['University of Notre Dame', 'und', 'nd.edu', 'e25e97d2-44fe-472b-bbfe-6efc71dae268'],
      ['University of Virginia','uva', 'virginia.edu', '63fd28df-4178-48e0-b259-343f82f04551'],
      ['Virginia Tech','vatech', 'vt.edu', '77b67409-2966-4ea9-95f8-fef59b12ee29']
  ]

  roles = %w(admin institutional_admin institutional_user)


  desc 'Setup Pharos'
  task setup: :environment do
    admintest = User.where(name: 'APTrustAdmin').first
    if admintest.nil?
      create_institutions(partner_list)
      create_roles(roles)
      create_users()
    else
      puts 'Nothing to do: Institution, groups, and admin user already exist.'
    end
    puts "You should be able to log in as ops@aptrust.org, with password 'password123'"
  end

  desc 'Set up user API key'
  task :set_user_api_key, [:user_email, :hex_length] => :environment do |_, args|
    args.with_defaults(:hex_length => 20)
    email = args[:user_email].to_s
    length = args[:hex_length].to_i
    user = User.where(email: email).first
    if user
      user.generate_api_key(length)
      if user.save!
        puts "Please record this key.  If you lose it, you will have to generate a new key. Your API secret key is: #{user.api_secret_key}"
      else
        puts 'ERROR: Unable to create API key.'
      end
    else
      puts "A user with email address #{email} could not be found. Please double check your inputs and the existence of said user."
    end
  end

  desc 'Update user API key'
  task :update_user_api_key, [:user_email, :api_key] => :environment do |_, args|
    email = args[:user_email].to_s
    hex_key = args[:api_key].to_s
    user = User.where(email: email).first
    if user
      if user.api_secret_key == hex_key
        puts 'The passed in API key matches the key that is already stored in the DB, no need to update.'
      else
        user.api_secret_key = hex_key
        if user.save!
          puts "Please record this key.  If you lose it, you will have to generate a new key. Your API secret key is: #{user.api_secret_key}"
        else
          puts 'ERROR: Unable to create API key.'
        end
      end
    else
      puts "A user with email address #{email} could not be found. Please double check your inputs and the existence of said user."
    end
  end

  desc 'Add type to previous institutions'
  task type_institutions: :environment do
    Institution.all.each do |inst|
      puts "Retyping #{inst.name} to be a member institution."
      inst.type = 'MemberInstitution'
      inst.save!
    end
  end

  desc 'Deactivate user'
  task :deactivate_user, [:email] => [:environment] do |t, args|
    user_email = args[:email]
    user = User.where(email: user_email).first
    user.soft_delete
    puts "User with email #{user_email} has been deactivated at #{user.deactivated_at}."
  end

  desc 'Reactivate user'
  task :reactivate_user, [:email] => [:environment] do |t, args|
    user_email = args[:email]
    user = User.where(email: user_email).first
    user.reactivate
    puts "User with email #{user_email} has been reactivated at #{Time.now}."
  end

  desc 'Deactivate all users at an institution'
  task :deactivate_institutions_users, [:identifier] => [:environment] do |t, args|
    inst_identifier = args[:identifier]
    institution = Institution.where(identifier: inst_identifier).first
    institution.deactivate
    puts "All users at #{institution.name} have been deactivated."
  end

  desc 'Reactivate all users at an institution'
  task :reactivate_institutions_users, [:identifier] => [:environment] do |t, args|
    inst_identifier = args[:identifier]
    institution = Institution.where(identifier: inst_identifier).first
    institution.reactivate
    puts "All users at #{institution.name} have been reactivated."
  end

  # For "APTrust Deposits By Month" spreadsheet on Google Docs
  #
  # Usage:
  #
  # rake pharos:print_storage_summary['2018-07-31']
  desc 'Print storage summary'
  task :print_storage_summary, [:end_date] => [:environment] do |t, args|
    print_storage_report(args[:end_date])
  end

  desc 'Two Factor Passwords'
  task :two_factor_passwords => :environment do
    User.all.each do |usr|
      usr.initial_password_updated = true
      usr.save!
      puts "#{usr.name} has been updated."
    end
  end

  desc 'Two Factor Emails'
  task :two_factor_emails => :environment do
    User.all.each do |usr|
      usr.email_verified = true
      usr.save!
      puts "#{usr.name} has been updated."
    end
  end

  desc 'Two Factor Account Confirmations'
  task :two_factor_account_confirmations => :environment do
    User.all.each do |usr|
      usr.account_confirmed = true
      usr.save!
      puts "#{usr.name} has been updated."
    end
  end

  desc 'Test User Grace Period'
  task :test_user_grace_period, [:user_email] => [:environment] do |t, args|
    email = args[:user_email]
    user = User.where(email: email).first
    user.grace_period = DateTime.now + 11.months
    user.save!
    puts "#{user.name}'s grace period for Two Factor Authentication has been reset for one year."
  end

  desc 'Update Grace Period'
  task :update_grace_period, [:user_email] => [:environment] do |t, args|
    email = args[:user_email]
    user = User.where(email: email).first
    user.grace_period = DateTime.now
    user.save!
    puts "#{user.name}'s grace period for Two Factor Authentication has been reset for another 30 days."
  end

  desc 'Pre Date Grace Periods'
  task :pre_date_user_grace_periods => :environment do
    User.all.each do |usr|
      usr.grace_period = DateTime.now - 30.days
      usr.save!
      puts "#{usr.name}'s grace period for Two Factor Authentication has been set for 30 days ago."
    end
  end

  desc 'Set Production Grace Periods'
  task :production_grace_periods => :environment do
    User.all.each do |usr|
      usr.grace_period = DateTime.now
      usr.save!
      puts "#{usr.name}'s grace period for Two Factor Authentication has been set for today."
    end
  end

  desc 'Deactivate Unused Accounts'
  task :deactive_unused_accounts => :environment do
    User.all.each do |usr|
      unless usr.account_confirmed
        usr.soft_delete
        puts "#{usr.name} has been deactivated."
      end
    end
  end

  desc 'Set SMS Defaults'
  task :set_sms_defaults => :environment do
    sms = Aws::SNS::Client.new
    response = sms.set_sms_attributes({
        attributes: {
          'DefaultSenderID' => 'APTrust',
          'DefaultSMSType' => 'Transactional',
        },
    })
  end

  desc 'Set Bucket Attributes'
  task :set_bucket_attributes => :environment do
    Institution.all.each do |inst|
      inst.receiving_bucket = "#{Pharos::Application.config.pharos_receiving_bucket_prefix}#{inst.identifier}"
      inst.restore_bucket = "#{Pharos::Application.config.pharos_restore_bucket_prefix}#{inst.identifier}"
      inst.save!
      puts "Updated Institution: #{inst.name}"
    end
  end

  # To get total GB deposited by each institution through the end of July, 2018:
  #
  # inst_storage_summary('2018-07-31')
  #
  def inst_storage_summary(end_date)
    gb = 1073741824.0
    # tb = 1099511627776.0
    report = {
      'end_date' => end_date,
      'institutions' => {}
    }
    Institution.all.each do |inst|
      byte_count = inst.active_files.where("created_at <= ?", end_date).sum(:size)
      gigabytes = (byte_count / gb).round(2)
      report['institutions'][inst.name] = gigabytes.to_f
    end
    return report
  end

  def print_storage_report(end_date)
    report = inst_storage_summary(end_date)
    puts "Total gigabytes of data deposited as of #{end_date}"
    report['institutions'].each do |name, gb|
      printf("%-50s %16.2f\n", name, gb)
    end
    return ''
  end

  def create_institutions(partner_list)
    partner_list.each do |partner|
      existing_inst = Institution.where(identifier: partner[2]).first
      if existing_inst.nil?
        puts "Creating #{partner[0]}"
        Institution.create!(name: partner[0],
                            identifier: partner[2],
                            type: 'MemberInstitution')
      else
        puts "#{partner[0]} already exists"
      end
    end
  end

  def create_roles(roles)
      puts "Creating roles 'admin', 'institutional_admin', and 'institutional_user'"
      roles.each do |role|
        Role.create!(name: role)
      end
  end

  def create_users
    puts 'Create an initial Super-User for APTrust...'
    aptrust = Institution.where(identifier: "aptrust.org").first
    admin_role = Role.where(name: 'admin').first
    name = "APTrustAdmin"
    email = "ops@aptrust.org"
    phone_number ="4341234567"
    password ="password123"
    User.create!(name: name, email: email, password: password,
                 phone_number: phone_number, institution_id: aptrust.id,
                 roles: [admin_role])
    puts "Created admin user"

    puts 'Creating system user for API use'
    name = "APTrust System"
    email = "system@aptrust.org"
    api_key = "75d35f5b6e324594a05045175661ba3785c02dde"
    User.create!(name: name, email: email, password: password,
                 phone_number: phone_number, institution_id: aptrust.id,
                 roles: [admin_role], api_secret_key: api_key)
    puts "Created system (API) user"

  end
end

namespace :db do
  desc "Checks to see if the database exists"
  task :exists do
    begin
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
    rescue
      exit 1
    else
      exit 0
    end
  end
end
