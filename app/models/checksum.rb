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
  scope :datetime_before, ->(param) { where('checksums.datetime < ?', param) unless param.blank? }
  scope :datetime_after, ->(param) { where('checksums.datetime > ?', param) unless param.blank? }
  scope :with_generic_file_identifier, ->(param) {
    joins(:generic_file)
        .where('generic_files.identifier = ?', param) unless param.blank?
  }
  scope :with_generic_file_identifier_like, ->(param) {
    joins(:generic_file)
        .where('generic_files.identifier LIKE ?', "%#{param}%") unless param.blank?
  }
  # TODO: find a way to make something like this work.
  # scope :with_institution, ->(param) {
  #   joins(:generic_file).joins(:intellectual_objects)
  #       .where('intellectual_objects.institution_id = ?', param) unless param.blank?
  # }

end
