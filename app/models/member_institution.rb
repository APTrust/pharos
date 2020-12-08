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
class MemberInstitution < Institution
  has_many :subscription_institutions

  def subscribers
    SubscriptionInstitution.where(member_institution_id: self.id).order('name')
  end

  def subscriber_report(total)
    si_report = {}
    total_size = total.to_f
    self.subscribers.each do |si|
      size = si.total_file_size.to_f
      si_report[si.name] = size
      total_size = total_size + size
    end
    si_report['total_bytes'] = total_size
    si_report
  end

  def generate_overview
    report = {}
    bytes = self.bytes_by_format
    total = bytes['all']
    report[:bytes_by_format] = bytes
    report[:intellectual_objects] = self.object_count
    report[:generic_files] = self.file_count
    report[:premis_events] = self.event_count
    report[:work_items] = self.item_count
    report[:average_file_size] = self.average_file_size
    report[:subscribers] = self.subscriber_report(total)
    report
  end

  def generate_basic_report
    report = {}
    report[:intellectual_objects] = self.object_count
    report[:generic_files] = self.file_count
    report[:premis_events] = self.event_count
    report[:work_items] = self.item_count
    if self.name == 'APTrust'
      report[:total_file_size] = Institution.total_file_size_across_repo
      report[:average_file_size] = Institution.average_file_size_across_repo
    else
      report[:total_file_size] = self.total_file_size
      report[:average_file_size] = self.average_file_size
      report[:subscribers] = self.subscriber_report(report[:total_file_size])
    end
    report
  end

  def generate_subscriber_report
    total_size = self.total_file_size
    self.subscriber_report(total_size)
  end

  def generate_cost_report
    report = {}
    report[:total_file_size] = self.total_file_size
    report[:subscribers] = self.subscriber_report(report[:total_file_size])
    report
  end

  def snapshot
    indiv_bytes = self.total_file_size
    indiv_cs_bytes = self.core_service_size
    indiv_go_bytes = self.glacier_only_size
    total_bytes = indiv_bytes
    total_cs_bytes = indiv_cs_bytes
    total_go_bytes = indiv_go_bytes
    snapshot_array = []
    self.subscribers.each do |si|
      snap = si.snapshot
      total_bytes = total_bytes + snap.apt_bytes
      total_cs_bytes = total_cs_bytes + snap.cs_bytes
      total_go_bytes = total_go_bytes + snap.go_bytes
      snapshot_array.push(snap)
    end
    if total_bytes < 10995116277760 #10 TB
      rounded_cost = 0.00
    else
      excess = total_bytes - 10995116277760
      cost = excess * 0.000000000381988
      rounded_cost = cost.round(2)
    end
    if indiv_bytes < 10995116277760 #10 TB
      rounded_indiv_cost = 0.00
    else
      indiv_excess = indiv_bytes - 10995116277760
      indiv_cost = indiv_excess * 0.000000000381988
      rounded_indiv_cost = indiv_cost.round(2)
    end
    rounded_cost = 0.00 if rounded_cost == 0.0
    rounded_indiv_cost = 0.00 if rounded_indiv_cost == 0.0
    indiv_snapshot = Snapshot.create(institution_id: self.id, audit_date: Time.now, apt_bytes: indiv_bytes, cs_bytes: indiv_cs_bytes, go_bytes: indiv_go_bytes, cost: rounded_indiv_cost, snapshot_type: 'Individual')
    indiv_snapshot.save!
    snapshot_array.push(indiv_snapshot)
    snapshot = Snapshot.create(institution_id: self.id, audit_date: Time.now, apt_bytes: total_bytes, cs_bytes: total_cs_bytes, go_bytes: total_go_bytes, cost: rounded_cost, snapshot_type: 'Subscribers Included')
    snapshot.save!
    snapshot_array.push(snapshot)
    snapshot_array
  end

  private

  def check_for_associations
    if User.where(institution_id: self.id).count != 0
      errors[:base] << "Cannot delete #{self.name} because some Users are associated with this Institution"
    end
    if self.intellectual_objects.count != 0
      errors[:base] << "Cannot delete #{self.name} because Intellectual Objects are associated with this Institution"
    end
    if self.generic_files.count != 0
      errors[:base] << "Cannot delete #{self.name} because Generic Files are associated with this Institution"
    end
    if self.premis_events.count != 0
      errors[:base] << "Cannot delete #{self.name} because Premis Events are associated with this Institution"
    end
    if WorkItem.where(institution_id: self.id).count != 0
      errors[:base] << "Cannot delete #{self.name} because Work Items are associated with this Institution"
    end
    if SubscriptionInstitution.where(member_institution_id: self.id).count != 0
      errors[:base] << "Cannot delete #{self.name} because Subscription Institutions are associated with this Institution"
    end
    if errors[:base].empty?
      true
    else
      throw(:abort)
    end
  end

end
