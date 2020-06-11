desc 'Run specs'
RSpec::Core::RakeTask.new(:rspec => 'test:prepare') { |t| t.rspec_opts = ['--colour', '--profile 20'] }

namespace :pharos do

  partner_list = [
      ['APTrust', 'apt', 'aptrust.org'],
      ['Columbia University', 'cul', 'columbia.edu'],
      ['Indiana University Bloomington', 'iub', 'indiana.edu'],
      ['Johns Hopkins University', 'jhu', 'jhu.edu'],
      ['North Carolina State University', 'ncsu', 'ncsu.edu'],
      ['Pennsylvania State University', 'pst', 'psu.edu'],
      ['Syracuse University', 'syr', 'syr.edu'],
      ['Test University','test', 'test.edu'],
      ['University of Chicago', 'uchi', 'uchicago.edu'],
      ['University of Cincinnati', 'ucin', 'uc.edu'],
      ['University of Connecticut', 'uconn', 'uconn.edu'],
      ['University of Maryland', 'mdu', 'umd.edu'],
      ['University of Miami', 'um', 'miami.edu'],
      ['University of Michigan', 'umich', 'umich.edu'],
      ['University of North Carolina at Chapel Hill', 'unc', 'unc.edu'],
      ['University of Notre Dame', 'und', 'nd.edu'],
      ['University of Virginia','uva', 'virginia.edu'],
      ['Virginia Tech','vatech', 'vt.edu']
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
    puts "or system@aptrust.org / password"
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

  desc 'Initialize staging environment'
  task :init_staging => :environment do
    staging_inst = [['Staging University', 'staging', 'staging.edu']]
    create_institutions(staging_inst)
    inst = Institution.find_by_identifier('staging.edu')
    user = User.find_by_email('staging_user@aptrust.org')
    if user.nil?
      inst_admin = Role.find_by_name('institutional_admin')
      User.create!(name: 'Staging User', email: 'staging_user@aptrust.org',
                   password: 'password123', phone_number: '555-555-5555',
                   institution_id: inst.id,
                   roles: [inst_admin],
                   grace_period: '2099-12-31 23:59:59',
                   sign_in_count: 10,
                   last_sign_in_at: 1.hour.ago,
                   email_verified: true,
                   force_password_update: false,
                   initial_password_updated: true,
                   api_secret_key: "d6022eb9c7b14469a4ad3d70ca5579a4e31dbfb3")
      puts "Created user staging_user@aptrust.org"
    else
      puts "User staging_user@aptrust.org already exists"
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
    grace_period = '2099-12-31 23:59:59'
    User.create!(name: name, email: email, password: password,
                 phone_number: phone_number, institution_id: aptrust.id,
                 roles: [admin_role], grace_period: grace_period)
    puts "Created admin user"

    puts 'Creating system user for API use'
    name = "APTrust System"
    email = "system@aptrust.org"
    api_key = "75d35f5b6e324594a05045175661ba3785c02dde"
    User.create!(name: name, email: email, password: password,
                 phone_number: phone_number, institution_id: aptrust.id,
                 roles: [admin_role], api_secret_key: api_key,
                 grace_period: grace_period)
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
