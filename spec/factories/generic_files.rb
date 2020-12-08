# == Schema Information
#
# Table name: generic_files
#
#  id                     :integer          not null, primary key
#  file_format            :string
#  size                   :bigint
#  identifier             :string
#  intellectual_object_id :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  state                  :string
#  last_fixity_check      :datetime         default(Sat, 01 Jan 2000 00:00:00 UTC +00:00), not null
#  ingest_state           :text
#  institution_id         :integer          not null
#  storage_option         :string           default("Standard"), not null
#  uuid                   :string           not null
#
FactoryBot.define do

  factory :generic_file do
    intellectual_object { FactoryBot.create(:intellectual_object) }
    identifier { "#{intellectual_object.identifier}/data/filename.xml" }
    file_format { 'application/xml' }
    uuid { SecureRandom.uuid }
    size { rand(20000..500000000) }
    created_at { "#{Time.now}" }
    updated_at { "#{Time.now}" }
    state { 'A' }
    last_fixity_check { '2000-01-01' }
    institution_id { intellectual_object.institution_id }
    storage_option { 'Standard' }
  end

end
