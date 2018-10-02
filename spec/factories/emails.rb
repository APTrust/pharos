FactoryBot.define do
  factory :fixity_email, class: 'Email'  do
    email_type { 'fixity' }
    event_identifier { SecureRandom.hex(16) }
    item_id { nil }
    intellectual_object_id { nil }
    generic_file_id { nil }
    email_text { 'This is the text of the email to be sent.' }
    institution_id { nil }
  end

  factory :restoration_email, class: 'Email'  do
    email_type { 'restoration' }
    event_identifier { nil }
    intellectual_object_id { nil }
    generic_file_id { nil }
    item_id { FactoryBot.create(:work_item).id }
    email_text { 'This is the text of the email to be sent.' }
    institution_id { nil }
  end

  factory :multiple_fixity_email, class: 'Email' do
    email_type { 'multiple_fixity' }
    premis_events {  }
    event_identifier { nil }
    intellectual_object_id { nil }
    generic_file_id { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
    institution_id { nil }
  end

  factory :multiple_restoration_email, class: 'Email' do
    email_type { 'multiple_restoration' }
    work_items {  }
    event_identifier { nil }
    item_id { nil }
    intellectual_object_id { nil }
    generic_file_id { nil }
    email_text { 'This is the text of the email to be sent.' }
    institution_id { nil }
  end

  factory :deletion_request_email, class: 'Email' do
    email_type { 'deletion_request' }
    intellectual_object_id { FactoryBot.create(:intellectual_object).id }
    generic_file_id { FactoryBot.create(:generic_file).id }
    institution_id { nil }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :bulk_deletion_request_email, class: 'Email' do
    email_type { 'bulk_deletion_request' }
    intellectual_object_id { nil }
    generic_file_id { nil }
    institution_id { FactoryBot.create(:institution).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :deletion_confirmation_email, class: 'Email' do
    email_type { 'deletion_confirmation' }
    intellectual_object_id { FactoryBot.create(:intellectual_object).id }
    generic_file_id { FactoryBot.create(:generic_file).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
    institution_id { nil }
  end

  factory :partial_bulk_deletion_confirmation_email, class: 'Email' do
    email_type { 'bulk_deletion_confirmation_partial' }
    intellectual_object_id { nil }
    generic_file_id { nil }
    institution_id { FactoryBot.create(:institution).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :final_bulk_deletion_confirmation_email, class: 'Email' do
    email_type { 'bulk_deletion_confirmation_final' }
    intellectual_object_id { nil }
    generic_file_id { nil }
    institution_id { FactoryBot.create(:institution).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :deletion_finished_email, class: 'Email' do
    email_type { 'deletion_finished' }
    intellectual_object_id { FactoryBot.create(:intellectual_object).id }
    generic_file_id { FactoryBot.create(:generic_file).id }
    institution_id { nil }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :bulk_deletion_finished_email, class: 'Email' do
    email_type { 'bulk_deletion_finished' }
    intellectual_object_id { nil }
    generic_file_id { nil }
    institution_id { FactoryBot.create(:institution).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :deletion_notification_email, class: 'Email' do
    email_type { 'deletion_notifications' }
    intellectual_object_id { nil }
    generic_file_id { nil }
    institution_id { FactoryBot.create(:institution).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end


end
