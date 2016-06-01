class PremisEvent < ActiveRecord::Base
  belongs_to :intellectual_object
  belongs_to :generic_file
end
