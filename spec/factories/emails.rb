FactoryBot.define do
  factory :fixity_email, class: 'Email'  do
    email_type { 'fixity' }
    event_identifier { SecureRandom.hex(16) }
    item_id { nil }
    intellectual_object_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :restoration_email, class: 'Email'  do
    email_type { 'restoration' }
    event_identifier { nil }
    intellectual_object_id { nil }
    item_id { FactoryBot.create(:work_item).id }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :multiple_fixity_email, class: 'Email' do
    email_type { 'multiple_fixity' }
    premis_events {  }
    event_identifier { nil }
    intellectual_object_id { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :multiple_restoration_email, class: 'Email' do
    email_type { 'multiple_restoration' }
    work_items {  }
    event_identifier { nil }
    item_id { nil }
    intellectual_object_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :deletion_request_email, class: 'Email' do
    email_type { 'deletion_request' }
    object_id { FactoryBot.create(:intellectual_object).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :deletion_confirmation_email, class: 'Email' do
    email_type { 'deletion_confirmation' }
    object_id { FactoryBot.create(:intellectual_object).id }
    event_identifier { nil }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end
end
