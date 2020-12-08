# == Schema Information
#
# Table name: snapshots
#
#  id             :bigint           not null, primary key
#  audit_date     :datetime
#  institution_id :integer
#  apt_bytes      :bigint
#  cost           :decimal(, )
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  snapshot_type  :string
#  cs_bytes       :bigint
#  go_bytes       :bigint
#
class Snapshot < ApplicationRecord
  self.primary_key = 'id'
  belongs_to :institution

  validates :institution_id, :audit_date, :apt_bytes, :snapshot_type, presence: true

  # We want this to always be true so that authorization happens in the user policy, preventing incorrect 404 errors.
  scope :readable, ->(current_user) { where('(1=1)') }

  def serializable_hash(options={})
    {
        institution_id: institution_id,
        audit_date: audit_date,
        aptrust_bytes: apt_bytes,
        cost: cost,
        snapshot_type: snapshot_type
    }
  end

end
