FactoryGirl.define do
  factory :fixity_email, class: 'Email'  do
    email_type { 'fixity' }
    event_identifier { SecureRandom.hex(16) }
    item_id { nil }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :restoration_email, class: 'Email'  do
    email_type { 'restoration' }
    event_identifier { nil }
    item_id { FactoryGirl.create(:work_item).id }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :multiple_fixity_email, class: 'Email' do
    email_type { 'multiple_fixity' }
    premis_events {  }
  end

  factory :multiple_restoration_email, class: 'Email' do
    email_type { 'multiple_restoration' }
    work_items {  }
  end
end
