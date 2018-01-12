class Snapshot < ApplicationRecord
  belongs_to :institution

  validates :institution_id, :audit_date, :apt_bytes, presence: true

end
