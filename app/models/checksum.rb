class Checksum < ActiveRecord::Base
  belongs_to :generic_file

  validates :digest, presence: true
  validates :algorithm, presence: true
  validates :datetime, presence: true
end
