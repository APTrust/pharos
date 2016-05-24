class Checksum < ActiveRecord::Base
  belongs_to :generic_file

  validates_presence_of :digest
  validates_presence_of :algorithm
  validates_presence_of :datetime
end
