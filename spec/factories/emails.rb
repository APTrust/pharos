FactoryGirl.define do
  factory :fixity_email do
    email_type { 'fixity' }
    event_identifier { SecureRandom.hex(16) }
    item_id { '' }
    email_text { 'This is the text of the email to be sent.' }
  end

  factory :restoration_email do
    email_type { 'restoration' }
    event_identifier { '' }
    item_id { FactoryGirl.create(:work_item).id }
    email_text { 'This is the text of the email to be sent.' }
  end
end
