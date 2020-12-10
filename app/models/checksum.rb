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
class Checksum < ActiveRecord::Base
  self.primary_key = 'id'
  belongs_to :generic_file

  validates :digest, presence: true
  validates :algorithm, presence: true
  validates :datetime, presence: true

  ### Scopes
  scope :with_digest, ->(param) { where(digest: param) unless param.blank? }
  scope :with_algorithm, ->(param) { where(algorithm: param) unless param.blank? }
  scope :created_before, ->(param) { where('checksums.created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('checksums.created_at > ?', param) unless param.blank? }
  scope :with_generic_file_identifier, ->(param) {
    joins(:generic_file)
        .where('generic_files.identifier = ?', param) unless param.blank?
  }
end
