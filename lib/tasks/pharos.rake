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
      puts "Nothing to do: Institution, groups, and admin user already exist."
    end
    puts "You should be able to log in as ops@aptrust.org, with password 'password'"
  end

  # Restricted only to non-production environments
  desc 'Empty the database'
  task empty_db: :environment do
    unless Rails.env.production?
      [User, GenericFile, IntellectualObject, Institution, Role, WorkItem, WorkItemState, PremisEvent, DpnWorkItem, Checksum].each(&:destroy_all)
    end
  end

  # desc 'Run ci'
  # task :travis do
  #   puts 'Updating Solr config'
  #   Rake::Task['jetty:config'].invoke
  #
  #   require 'jettywrapper'
  #   jetty_params = Jettywrapper.load_config
  #   puts 'Starting Jetty'
  #   error = Jettywrapper.wrap(jetty_params) do
  #     Rake::Task['rspec'].invoke
  #   end
  #   raise "test failures: #{error}" if error
  # end

  desc 'Empty DB and add dummy information'
  task :populate_db, [:numIntObjects, :numGenFiles] => [:environment] do |_, args|
    if Rails.env.production?
      puts 'Do not run in production!'
      return
    end
    Rake::Task['pharos:empty_db'].invoke
    Rake::Task['pharos:setup'].invoke

    start = Time.now
    puts "Starting time: #{start}"

    args.with_defaults(:numIntObjects => 3, :numGenFiles => 3)

    puts 'Creating Users for each Institution'
    Institution.all.each do |institution|
      next unless institution.name != 'APTrust'

      puts "Populating content for #{institution.name}"

      num_users = rand(1..5)
      num_users.times.each do |count|
        puts "== Creating user #{count+1} of #{num_users} for #{institution.name}"
        FactoryGirl.create(:user, :institutional_user, institution_id: institution.id)
      end

      num_items = args[:numIntObjects].to_i
      num_items.times.each do |count|
        puts "== Creating intellectual object #{count+1} of #{num_items} for #{institution.name}"
        name = "#{SecureRandom.uuid}"
        bag_name = "#{name}.tar"
        ident = "#{institution.identifier}/#{name}"
        item = FactoryGirl.create(:intellectual_object, institution: institution, identifier: ident, bag_name: bag_name)
        item.save!
        item.add_event(FactoryGirl.attributes_for(:premis_event_ingest, detail: 'Metadata recieved from bag.', outcome_detail: 'something', outcome_information: 'Parsed as part of bag submission.'))
        item.add_event(FactoryGirl.attributes_for(:premis_event_identifier, outcome_detail: item.id, outcome_information: 'Assigned by Rake.'))

        #add Work item for intellectual object
        wi = FactoryGirl.create(:work_item, institution: institution, intellectual_object: item, name: name, action: Pharos::Application::PHAROS_ACTIONS['ingest'], stage: Pharos::Application::PHAROS_STAGES['record'], status: Pharos::Application::PHAROS_STATUSES['success'])
        FactoryGirl.create(:work_item_state, work_item: wi)

        # 5.times.each do |count|
        #   FactoryGirl.create(:work_item, institution: institution, intellectual_object: item, name: name)
        # end

        num_files = args[:numGenFiles].to_i
        num_files.times.each do |file_count|
          puts "== ** Creating generic file object #{file_count+1} of #{num_files} for intellectual_object #{ item.id }"
          format = [
              {ext: 'txt', type: 'plain/text'},
              {ext: 'xml', type: 'application/xml'},
              {ext: 'xml', type: 'application/rdf+xml'},
              {ext: 'pdf', type: 'application/pdf'},
              {ext: 'tif', type: 'image/tiff'},
              {ext: 'mp4', type: 'video/mp4'},
              {ext: 'wav', type: 'audio/wav'},
              {ext: 'pdf', type: 'application/pdf'}
          ].sample
          create = [
            '2016-09-21 00:00:00 -0000',
            '2016-09-22 00:00:00 -0000',
            '2016-09-23 00:00:00 -0000',
            '2016-09-24 00:00:00 -0000',
            '2016-09-25 00:00:00 -0000',
            '2016-09-26 00:00:00 -0000',
            '2016-09-27 00:00:00 -0000'
          ].sample
          name = Faker::Lorem.characters(char_count=rand(5..15))
          attrs = {
              file_format: "#{format[:type]}",
              uri: "file:///#{item.identifier}/data/#{name}#{file_count}.#{format[:ext]}",
              identifier: "#{item.identifier}/data/#{name}#{file_count}.#{format[:ext]}",
          }
          f = FactoryGirl.build(:generic_file, intellectual_object: item, file_format: attrs[:file_format], uri: attrs[:uri], identifier: attrs[:identifier], created_at: create)
          f.save!
          f.add_event(FactoryGirl.attributes_for(:premis_event_validation, institution: institution))
          f.add_event(FactoryGirl.attributes_for(:premis_event_ingest, institution: institution))
          f.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation, institution: institution))
          f.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check, institution: institution))
          f.save!
        end
      end
    end
  end

  desc 'Deletes all solr documents and work items, recreates institutions & preserves users'
  task :reset_data => [:environment] do
    if Rails.env.production?
      puts 'Do not run in production!'
      return
    end
    Rake::Task['pharos:empty_db'].invoke
    Rake::Task['pharos:setup'].invoke
  end

  desc 'Deletes test.edu data from Go integration tests'
  task :delete_go_data => [:environment] do
    if Rails.env.production?
      puts 'Do not run in production!'
      return
    end
    count = WorkItem.where(institution: 'test.edu').delete_all
    puts "Deleted #{count} WorkItems for test.edu"
    IntellectualObject.all.each do |io|
      if io.identifier.start_with?('test.edu/')
        puts "Deleting IntellectualObject #{io.identifier}"
        io.generic_files.destroy_all
        io.destroy
      end
    end
    finish = Time.now
    diff = finish - start
    puts "Execution time is #{diff} seconds"
  end

  desc 'Dumps objects, files, institutions and events to JSON files for auditing'
  task :dump_data, [:data_dir, :since_when] => [:environment] do |t, args|
    #
    # Sample usage to dump all objects and institutions into /usr/local/data:
    #
    # bundle exec rake pharos:dump_data[/usr/local/data]
    #
    # To dump objects updated since a specified time to the same directory:
    #
    # bundle exec rake pharos:dump_data[/usr/local/data,'2016-01-04T20:00:48.248Z']
    #
    data_dir = args[:data_dir] || '.'
    since_when = args[:since_when] || DateTime.new(1900,1,1).iso8601
    inst_file = File.join(data_dir, "institutions.json")
    puts "Dumping institutions to #{inst_file}"
    File.open(inst_file, 'w') do |file|
      Institution.all.each do |inst|
        file.puts(inst.to_json)
      end
    end
    objects_file = File.join(data_dir, 'objects.json')
    timestamp_file = File.join(data_dir, 'timestamp.txt')
    last_timestamp = since_when
    proceed_to_reify = false
    number_skipped = 0
    puts "Dumping objects, files and events modified since #{since_when} to #{objects_file}"
    begin
      File.open(objects_file, 'w') do |file|
        IntellectualObject.find_in_batches([], batch_size: 10, sort: 'system_modified_dtsi asc') do |solr_result|
          # Don't process or even reify results we've already processed,
          # because the reify process blows up the memory and leads
          # to out-of-memory crashes. We have to keep track of the last
          # intellectual object we processed, because memory leaks somewhere
          # in the Rails/Hydra/ActiveFedora stack cause this process to crash
          # consistently, and we need to be able to restart where we left off.
          if proceed_to_reify == false
            solr_result.each do |result|
              record_modified = result['system_modified_dtsi']
              if record_modified > since_when
                proceed_to_reify = true
                break
              end
              number_skipped += 1
            end
          end
          next if proceed_to_reify == false
          obj_list = ActiveFedora::SolrService.reify_solr_results(solr_result)
          obj_list.each do |io|
            data = io.serializable_hash(include: [:premisEvents])
            data[:generic_files] = []
            io.generic_files.each do |gf|
              data[:generic_files].push(gf.serializable_hash(include: [:checksum, :premisEvents]))
            end
            file.puts(data.to_json)
            last_timestamp = io.modified_date
          end

          # Do our part to remediate memory leaks
          obj_list.each { |io| io = nil }
          obj_list = nil
          solr_result = nil
          data = nil
          GC.start
        end
      end
    ensure
      puts("Skipped #{number_skipped} records modified before #{since_when}.")
      puts("Finished dumping objects with last mod date through #{last_timestamp}")
      puts("Writing timestamp to #{timestamp_file}")
      puts("If this process crashed, you can resume the data dump where it left off.")
      puts("First, MOVE THE FILE #{objects_file} SO IT DOESN'T GET OVERWRITTEN.")
      puts("Then run the following command:")
      puts("bundle exec rake pharos:dump_data[#{data_dir},'#{last_timestamp}']")
      File.open(timestamp_file, 'w') { |file| file.puts(last_timestamp) }
    end
  end

  desc 'Dumps WorkItem records to JSON files for auditing'
  task :dump_work_items, [:data_dir, :since_when] => [:environment] do |t, args|
    data_dir = args[:data_dir] || '.'
    since_when = args[:since_when] || DateTime.new(1900,1,1).iso8601
    output_file = File.join(data_dir, "work_items.json")
    puts "Dumping work_items to #{output_file}"
    File.open(output_file, 'w') do |file|
      WorkItem.where("updated_at >= ?", since_when).order('updated_at asc').find_each do |item|
        file.puts(item.to_json)
      end
    end
  end

  desc 'Dumps User records to JSON files for auditing'
  task :dump_users, [:data_dir] => [:environment] do |t, args|
    data_dir = args[:data_dir] || '.'
    output_file = File.join(data_dir, "users.json")
    puts "Dumping users to #{output_file}"
    File.open(output_file, 'w') do |file|
      User.find_each do |user|
        data = user.serializable_hash
        data['encrypted_password'] = user.encrypted_password
        data['encrypted_api_secret_key'] = user.encrypted_api_secret_key
        file.puts(data.to_json)
      end
    end
  end

  desc 'Transition Fluctus data from sqlite db to Pharos'
  task :transition_Fluctus => :environment do
    db = SQLite3::Database.new('fedora_export.db')
    create_roles(roles)
    admin_role = Role.where(name: 'admin').first
    inst_admin_role = Role.where(name: 'institutional_admin').first
    inst_user_role = Role.where(name: 'institutional_user').first
    changed_events = []

    db.execute('SELECT id, name, brief_name, identifier, dpn_uuid FROM institutions') do |inst_row|
      current_inst = Institution.create(name: inst_row[1], brief_name: inst_row[2], identifier: inst_row[3],
                                        dpn_uuid: inst_row[4], state: 'A')
       puts "Created Institution: #{current_inst.name}"

      db.execute('SELECT id, email, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at,
                sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, created_at,
                updated_at, name, phone_number, institution_pid, encrypted_api_secret_key, roles FROM users WHERE
                institution_pid = ?', inst_row[0]) do |u_row|
        if u_row[17] == 'Inst_User'
          user = User.create(email: u_row[1], password: 'password', reset_password_token: nil, reset_password_sent_at: nil,
                             remember_created_at: u_row[5], sign_in_count: u_row[6], current_sign_in_at: u_row[7], last_sign_in_at: u_row[8],
                             current_sign_in_ip: u_row[9], last_sign_in_ip: u_row[10], created_at: u_row[11], updated_at: u_row[12], name: u_row[13],
                             phone_number: u_row[14], institution_id: current_inst.id, encrypted_api_secret_key: u_row[16], roles: [inst_user_role])
        elsif u_row[17] == 'Inst_Admin'
          user = User.create(email: u_row[1], password: 'password', reset_password_token: nil, reset_password_sent_at: nil,
                             remember_created_at: u_row[5], sign_in_count: u_row[6], current_sign_in_at: u_row[7], last_sign_in_at: u_row[8],
                             current_sign_in_ip: u_row[9], last_sign_in_ip: u_row[10], created_at: u_row[11], updated_at: u_row[12], name: u_row[13],
                             phone_number: u_row[14], institution_id: current_inst.id, encrypted_api_secret_key: u_row[16], roles: [inst_admin_role])
        elsif u_row[17] == 'Admin'
          user = User.create(email: u_row[1], password: 'password', reset_password_token: nil, reset_password_sent_at: nil,
                             remember_created_at: u_row[5], sign_in_count: u_row[6], current_sign_in_at: u_row[7], last_sign_in_at: u_row[8],
                             current_sign_in_ip: u_row[9], last_sign_in_ip: u_row[10], created_at: u_row[11], updated_at: u_row[12], name: u_row[13],
                             phone_number: u_row[14], institution_id: current_inst.id, encrypted_api_secret_key: u_row[16], roles: [admin_role])
        end
        puts " * Created User: #{u_row[13]}"
      end

      counter = 0

      db.execute('SELECT id, identifier, title, description, alt_identifier, access, bag_name, institution_id, state FROM
                intellectual_objects WHERE institution_id = ?', inst_row[0]) do |io_row|
        current_obj = IntellectualObject.create(identifier: io_row[1], title: io_row[2], description: io_row[3],
                                                alt_identifier: io_row[4], access: io_row[5], bag_name: io_row[6],
                                                institution_id: current_inst.id, state: io_row[8], etag: nil, dpn_uuid: nil)
        counter = counter + 1
        puts " * #{counter}"

        db.execute('SELECT intellectual_object_id, institution_id, intellectual_object_identifier, identifier, event_type,
                  date_time, detail, outcome, outcome_detail, outcome_information, object, agent, generic_file_id FROM
                  premis_events WHERE intellectual_object_id = ?', io_row[0]) do |pe_row|
          if pe_row[12].nil?
            io_ident_count = PremisEvent.where('identifier LIKE ?', "%#{pe_row[3]}%").count
            if io_ident_count == 0
              io_file = PremisEvent.create(intellectual_object_id: current_obj.id, institution_id: current_inst.id, intellectual_object_identifier: pe_row[2],
                                           identifier: pe_row[3], event_type: pe_row[4], date_time: pe_row[5], detail: pe_row[6], outcome: pe_row[7],
                                           outcome_detail: pe_row[8], outcome_information: pe_row[9], object: pe_row[10], agent: pe_row[11])
            else
              pe_identifier = SecureRandom.hex(16)
              io_file = PremisEvent.create(intellectual_object_id: current_obj.id, institution_id: current_inst.id, intellectual_object_identifier: pe_row[2],
                                           identifier: pe_identifier, event_type: pe_row[4], date_time: pe_row[5], detail: pe_row[6], outcome: pe_row[7],
                                           outcome_detail: pe_row[8], outcome_information: pe_row[9], object: pe_row[10], agent: pe_row[11])
              io_file.old_uuid = pe_row[3]
              changed_events.push(io_file)
            end
            io_file.save!
          end
        end

        db.execute('SELECT id, file_format, uri, size, intellectual_object_id, identifier, created_at, updated_at FROM
                  generic_files WHERE intellectual_object_id = ?', io_row[0]) do |gf_row|
          current_file = GenericFile.create(file_format: gf_row[1], uri: gf_row[2], size: gf_row[3],
                                            intellectual_object_id: current_obj.id, identifier: gf_row[5],
                                            created_at: gf_row[6], updated_at: gf_row[7], state: current_obj.state)

          db.execute('SELECT intellectual_object_id, institution_id, intellectual_object_identifier, identifier, event_type,
                  date_time, detail, outcome, outcome_detail, outcome_information, object, agent, generic_file_id,
                  generic_file_identifier FROM premis_events WHERE generic_file_id = ?', gf_row[0]) do |pe_gf_row|
            gf_ident_count = PremisEvent.where('identifier LIKE ?', "%#{pe_gf_row[3]}%").count
            if gf_ident_count == 0
              gf_file = PremisEvent.create(intellectual_object_id: current_obj.id, institution_id: current_inst.id, intellectual_object_identifier: pe_gf_row[2],
                                           identifier: pe_gf_row[3], event_type: pe_gf_row[4], date_time: pe_gf_row[5], detail: pe_gf_row[6],
                                           outcome: pe_gf_row[7], outcome_detail: pe_gf_row[8], outcome_information: pe_gf_row[9], object: pe_gf_row[10],
                                           agent: pe_gf_row[11], generic_file_id: current_file.id, generic_file_identifier: pe_gf_row[13])
            else
              gf_pe_identifier = SecureRandom.hex(16)
              gf_file = PremisEvent.create(intellectual_object_id: current_obj.id, institution_id: current_inst.id, intellectual_object_identifier: pe_gf_row[2],
                                           identifier: gf_pe_identifier, event_type: pe_gf_row[4], date_time: pe_gf_row[5], detail: pe_gf_row[6],
                                           outcome: pe_gf_row[7], outcome_detail: pe_gf_row[8], outcome_information: pe_gf_row[9], object: pe_gf_row[10],
                                           agent: pe_gf_row[11], generic_file_id: current_file.id, generic_file_identifier: pe_gf_row[13])
              gf_file.old_uuid = pe_gf_row[3]
              changed_events.push(gf_file)
            end
            gf_file.save!
          end

          db.execute('SELECT algorithm, datetime, digest, generic_file_id FROM checksums WHERE
                    generic_file_id = ?', gf_row[0]) do |ck_row|
            Checksum.create(algorithm: ck_row[0], datetime: ck_row[1], digest: ck_row[2], generic_file_id: current_file.id)
          end
        end
      end
    end

    puts 'Creating work items'
    db.execute 'SELECT id, created_at, updated_at, name, etag, bucket, user, institution, note, action, stage, status, outcome,
                bag_date, date, retry, reviewed, object_identifier, generic_file_identifier, state, node, pid, needs_admin_review
                FROM processed_items' do |row|
      inst = Institution.where(identifier: row[7]).first
      object = IntellectualObject.where(identifier: row[17]).first unless row[17].nil?
      file = GenericFile.where(identifier: row[18]).first unless row[18].nil?

      wi = WorkItem.create(created_at: row[1], updated_at: row[2], name: row[3], etag: row[4], bucket: row[5], user: row[6],
                      institution_id: inst.id, note: row[8], action: row[9], stage: row[10], status: row[11], outcome: row[12],
                      bag_date: row[13], date: row[14], retry: row[15], node: row[20], pid: row[21], needs_admin_review: row[22],
                      queued_at: nil, work_item_state_id: nil, size: nil, stage_started_at: nil)
      wi.intellectual_object_id = object.id if object
      wi.object_identifier = object.identifier if object
      wi.generic_file_id = file.id if file
      wi.generic_file_identifier = file.identifier if file
    end

    puts "Number of users in Pharos: #{User.all.count}"
    db.execute 'SELECT COUNT(*) FROM users' do |row|
      puts "Number of user rows in SQL db: #{row[0]}"
    end

    puts "Number of institutions in Pharos: #{Institution.all.count}"
    db.execute 'SELECT COUNT(*) FROM institutions' do |row|
      puts "Number of institution SQL in new db: #{row[0]}"
    end

    puts "Number of work items in Pharos: #{WorkItem.all.count}"
    db.execute 'SELECT COUNT(*) FROM processed_items' do |row|
      puts "Number of processed item SQL in new db: #{row[0]}"
    end

    puts "Number of intellectual objects in Pharos: #{IntellectualObject.all.count}"
    db.execute 'SELECT COUNT(*) FROM intellectual_objects' do |row|
      puts "Number of object rows in SQL db: #{row[0]}"
    end

    puts "Number of generic files in Pharos: #{GenericFile.all.count}"
    db.execute 'SELECT COUNT(*) FROM generic_files' do |row|
      puts "Number of file rows in SQL db: #{row[0]}"
    end

    puts "Number of premis events in Pharos: #{PremisEvent.all.count}"
    db.execute 'SELECT COUNT(*) FROM premis_events' do |row|
      puts "Number of event rows in SQL db: #{row[0]}"
    end

    puts "Number of checksums in Pharos: #{Checksum.all.count}"
    db.execute 'SELECT COUNT(*) FROM checksums' do |row|
      puts "Number of checksum rows in SQL db: #{row[0]}"
    end

    puts 'Following is a list of all of the events whose identifiers had to be changed:'
    event_count = 1
    changed_events.each do |event|
      puts "#{event_count}. ID: #{event.id} | Previous Identifier: #{event.old_uuid} | New Identifier: #{event.identifier}"
      event_count = event_count + 1
    end

  end

  def create_institutions(partner_list)
    partner_list.each do |partner|
      existing_inst = Institution.where(identifier: partner[2]).first
      if existing_inst.nil?
        puts "Creating #{partner[0]}"
        Institution.create!(name: partner[0],
                            brief_name: partner[1],
                            identifier: partner[2],
                            dpn_uuid: partner[3])
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
    password ="password"
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
