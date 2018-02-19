class Snapshot < ApplicationRecord
  belongs_to :institution

  validates :institution_id, :audit_date, :apt_bytes, presence: true

  def serializable_hash(options={})
    {
        institution_id: institution_id,
        audit_date: audit_date,
        aptrust_bytes: apt_bytes,
        dpn_bytes: dpn_bytes,
        cost: cost
    }
  end

end
