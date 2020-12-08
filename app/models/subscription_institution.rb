# == Schema Information
#
# Table name: institutions
#
#  id                    :integer          not null, primary key
#  name                  :string
#  identifier            :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  state                 :string
#  type                  :string
#  member_institution_id :integer
#  deactivated_at        :datetime
#  otp_enabled           :boolean
#  receiving_bucket      :string           not null
#  restore_bucket        :string           not null
#
class SubscriptionInstitution  < Institution
  belongs_to :member_institution

  validate :has_associated_member_institution

  def generate_overview
    report = {}
    report[:bytes_by_format] = self.bytes_by_format
    report[:intellectual_objects] = self.object_count
    report[:generic_files] = self.file_count
    report[:premis_events] = self.event_count
    report[:work_items] = self.item_count
    report[:average_file_size] = self.average_file_size
    report
  end

  def generate_basic_report
    report = {}
    report[:intellectual_objects] = self.object_count
    report[:generic_files] = self.file_count
    report[:premis_events] = self.event_count
    report[:work_items] = self.item_count
    report[:average_file_size] = self.average_file_size
    report[:total_file_size] = self.total_file_size
    report
  end

  def generate_subscriber_report
    report = {}
  end

  def generate_cost_report
    report = {}
    report[:total_file_size] = self.total_file_size
    report
  end

  def snapshot
    apt_bytes = self.total_file_size
    cs_bytes = self.core_service_size
    go_bytes = self.glacier_only_size
    cost = apt_bytes * 0.000000000381988
    rounded_cost = cost.round(2)
    rounded_cost = 0.00 if rounded_cost == 0.0
    snapshot = Snapshot.create(institution_id: self.id, audit_date: Time.now, apt_bytes: apt_bytes, cs_bytes: cs_bytes, go_bytes: go_bytes, cost: rounded_cost, snapshot_type: 'Individual')
    snapshot.save!
    snapshot
  end

  private

  def has_associated_member_institution
    errors.add(:member_institution_id, 'cannot be nil') if self.member_institution_id.nil?
  end

end
