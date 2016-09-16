FactoryGirl.define do

  factory :generic_file do
    intellectual_object { FactoryGirl.create(:intellectual_object) }
    identifier { "#{intellectual_object.identifier}/data/filename.xml" }
    file_format { 'application/xml' }
    uri { 'file://test/data/filename.xml' }
    size { rand(20000..500000000) }
    created_at { "#{Time.now}" }
    updated_at { "#{Time.now}" }
    state { 'A' }
  end

end
