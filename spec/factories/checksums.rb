# == Schema Information
#
# Table name: checksums
#
#  id              :integer          not null, primary key
#  algorithm       :string
#  datetime        :datetime
#  digest          :string
#  generic_file_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :checksum do
    algorithm { 'sha256' }
    datetime { Time.now.to_s }
    digest { SecureRandom.hex }
  end
end
