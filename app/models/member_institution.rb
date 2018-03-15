class MemberInstitution < Institution
  has_many :subscription_institutions

  def subscribers
    SubscriptionInstitution.where(member_institution_id: self.id).order('name')
  end

  def subscriber_report(total)
    si_report = {}
    total_size = total
    self.subscribers.each do |si|
      size = si.generic_files.sum(:size)
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
    report[:intellectual_objects] = self.intellectual_objects.where(state: 'A').count
    report[:generic_files] = self.generic_files.where(state: 'A').count
    report[:premis_events] = self.premis_events.count
    report[:work_items] = WorkItem.with_institution(self.id).count
    report[:average_file_size] = average_file_size
    report[:subscribers] = self.subscriber_report(total)
    report
  end

  def generate_basic_report
    report = {}
    if self.name == 'APTrust'
      files = GenericFile.where(state: 'A')
      report[:intellectual_objects] = IntellectualObject.where(state: 'A').count
      report[:generic_files] = files.count
      report[:premis_events] = PremisEvent.count
      report[:work_items] = WorkItem.count
      report[:total_file_size] = files.sum(:size)
      report[:average_file_size] = files.average(:size)
    else
      files = self.generic_files.where(state: 'A')
      report[:intellectual_objects] = self.intellectual_objects.where(state: 'A').count
      report[:generic_files] = files.count
      report[:premis_events] = PremisEvent.where(institution_id: self.id).count
      report[:work_items] = WorkItem.with_institution(self.id).count
      report[:total_file_size] = files.sum(:size)
      report[:average_file_size] = files.average(:size)
      report[:subscribers] = self.subscriber_report(report[:total_file_size])
    end
    report
  end

  def generate_subscriber_report
    total_size = self.generic_files.where(state: 'A').sum(:size)
    self.subscriber_report(total_size)
  end

  def generate_cost_report
    report = {}
    report[:total_file_size] = self.generic_files.where(state: 'A').sum(:size)
    report[:subscribers] = self.subscriber_report(report[:total_file_size])
    report
  end

  def snapshot
    indiv_bytes = self.active_files.sum(:size)
    total_bytes = indiv_bytes
    snapshot_array = []
    self.subscribers.each do |si|
      total_bytes = total_bytes + si.active_files.sum(:size)
      snapshot_array.push(si.snapshot)
    end
    if total_bytes < 10995116277760 #10 TB
      rounded_cost = 0.00
    else
      excess = total_bytes - 10995116277760
      cost = excess * 0.000000000381988
      rounded_cost = cost.round(2)
    end
    rounded_cost = 0.00 if rounded_cost == 0.0
    indiv_cost = indiv_bytes * 0.000000000381988
    rounded_indiv_cost = indiv_cost.round(2)
    rounded_indiv_cost = 0.00 if rounded_indiv_cost == 0.0
    indiv_snapshot = Snapshot.create(institution_id: self.id, audit_date: Time.now, apt_bytes: indiv_bytes, cost: rounded_indiv_cost, snapshot_type: 'Individual')
    indiv_snapshot.save!
    snapshot_array.push(indiv_snapshot)
    snapshot = Snapshot.create(institution_id: self.id, audit_date: Time.now, apt_bytes: total_bytes, cost: rounded_cost, snapshot_type: 'Subscribers Included')
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