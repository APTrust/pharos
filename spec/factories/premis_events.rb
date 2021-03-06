FactoryBot.define do

  factory :premis_event_ingest, class: 'PremisEvent' do
    identifier { SecureRandom.hex(16) }
    event_type { Pharos::Application::PHAROS_EVENT_TYPES['ingest'] }
    date_time { "#{Time.now}" }
    detail { 'Completed copy to S3 storage' }
    outcome { 'Success' }
    outcome_detail { "MD5:#{SecureRandom.hex(16)}" }
    outcome_information { 'Multipart Put using md5 checksum' }
    object { 'Goamz S3 Client' }
    agent { 'https://github.com/crowdmob/goamz' }
    factory :premis_event_ingest_fail, class: 'PremisEvent' do
      detail { 'Error copying to S3' }
      outcome { 'Failure' }
    end

  end

  factory :premis_event_validation, class: 'PremisEvent' do
    identifier { SecureRandom.hex(16) }
    event_type { Pharos::Application::PHAROS_EVENT_TYPES['validate'] }
    date_time { "#{Time.now}" }
    detail { 'Check against bag manifest checksum' }
    outcome { 'Success' }
    outcome_detail { '"MD5:#{SecureRandom.hex(16)}"' }
    object { 'https://github.com/APTrust/bagins' }
    agent { 'ruby s3 copy library' }
  end

  factory :premis_event_deletion, class: 'PremisEvent' do
    identifier { SecureRandom.hex(16) }
    event_type { Pharos::Application::PHAROS_EVENT_TYPES['delete'] }
    date_time { "#{Time.now}" }
    detail { 'Marked object or file for deletion' }
    outcome { 'Success' }
    outcome_detail { '"MD5:#{SecureRandom.hex(16)}"' }
    object { 'https://github.com/APTrust/pharos' }
    agent { 'http://www.ruby-doc.org/' }
  end

  factory :premis_event_fixity_generation, class: 'PremisEvent' do
    identifier { SecureRandom.hex(16) }
    event_type { Pharos::Application::PHAROS_EVENT_TYPES['digest_calc'] }
    date_time { "#{Time.now}" }
    detail { 'Calculated new fixity value' }
    outcome { 'Success' }
    outcome_detail { "sha256:#{SecureRandom.hex(64)}" }
    object { 'Go language cryptohash' }
    agent {'http://golang.org'}
    factory :premis_event_fixity_generation_fail, class: 'PremisEvent' do
      outcome { 'Failure' }
      detail { 'Error reading file' }
      outcome_information { "error: unable to find file 'testfile.xml'" }
    end
  end

  factory :premis_event_fixity_check, class: 'PremisEvent' do
    identifier { SecureRandom.hex(16) }
    event_type { Pharos::Application::PHAROS_EVENT_TYPES['fixity'] }
    date_time { "#{Time.now}" }
    detail { 'Fixity check against registered hash' }
    outcome { 'Success' }
    outcome_detail { "SHA256:#{SecureRandom.hex(64)}" }
    outcome_information { 'Fixity matches' }
    object { 'Go language cryptohash' }
    agent { 'http://golang.org/' }
    factory :premis_event_fixity_check_fail, class: 'PremisEvent' do
      outcome { 'Failure' }
      detail { 'Error, fixity does not match expected value' }
      outcome_information { "Acutal calculated hash was SHA256:#{SecureRandom.hex(64)}" }
    end
  end

  factory :premis_event_identifier, class: 'PremisEvent' do
    identifier { SecureRandom.hex(16) }
    event_type { Pharos::Application::PHAROS_EVENT_TYPES['ident_assignment'] }
    date_time { "#{Time.now}" }
    detail { 'S3 key generated for file' }
    outcome { 'Success' }
    outcome_detail { "#{SecureRandom.uuid()}" }
    outcome_information { 'Generated with ruby SecureRandom.uuid()' }
    object { 'Ruby 2.0.1' }
    agent { 'http://www.ruby-doc.org/' }
    factory :premis_event_identifier_fail, class: 'PremisEvent' do
      outcome { 'Failure' }
      detail {'Error generating S3 key'}
      outcome_detail { 'Identifier not set' }
      outcome_information { 'File not found' }
    end
  end

end
