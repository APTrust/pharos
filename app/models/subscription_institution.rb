class SubscriptionInstitution  < Institution
  belongs_to :member_institution

  validate :has_associated_member_institution

  def generate_overview
    report = {}
    report[:bytes_by_format] = self.bytes_by_format
    report[:intellectual_objects] = self.intellectual_objects.with_state('A').count
    report[:generic_files] = self.active_files.count
    report[:premis_events] = self.premis_events.count
    report[:work_items] = WorkItem.with_institution(self.id).count
    report[:average_file_size] = average_file_size
    report
  end

  def generate_basic_report
    report = {}
    report[:intellectual_objects] = self.intellectual_objects.with_state('A').count
    report[:generic_files] = self.active_files.count
    report[:premis_events] = self.premis_events.count
    report[:work_items] = WorkItem.with_institution(self.id).count
    report[:average_file_size] = self.average_file_size
    report[:total_file_size] = self.active_files.sum(:size)
    report
  end

  def generate_subscriber_report
    report = {}
  end

  def generate_cost_report
    report = {}
    report[:total_file_size] = self.active_files.sum(:size)
    report
  end

  def snapshot
    apt_bytes = self.active_files.sum(:size)
    cost = apt_bytes * 0.000000000381988
    rounded_cost = cost.round(2)
    rounded_cost = 0.00 if rounded_cost == 0.0
    snapshot = Snapshot.create(institution_id: self.id, audit_date: Time.now, apt_bytes: apt_bytes, cost: rounded_cost, snapshot_type: 'Individual')
    snapshot.save!
    snapshot
  end

  private

  def has_associated_member_institution
    errors.add(:member_institution_id, 'cannot be nil') if self.member_institution_id.nil?
  end

end