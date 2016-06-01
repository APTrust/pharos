class PremisEvent < ActiveRecord::Base
  belongs_to :intellectual_object
  belongs_to :generic_file

  validates :identifier,  presence: true
  validates :event_type,  presence: true
  validates :date_time,  presence: true
  validates :detail,  presence: true
  validates :outcome,  presence: true
  validates :outcome_detail,  presence: true
  validates :object,  presence: true
  validates :agent,  presence: true

end
