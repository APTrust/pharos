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
      report[:intellectual_objects] = IntellectualObject.where(state: 'A').count
      report[:generic_files] = GenericFile.where(state: 'A').count
      report[:premis_events] = PremisEvent.count
      report[:work_items] = WorkItem.count
      report[:average_file_size] = average_file_size_across_repo
      report[:total_file_size] = GenericFile.where(state: 'A').sum(:size)
    else
      report[:intellectual_objects] = self.intellectual_objects.where(state: 'A').count
      report[:generic_files] = self.generic_files.where(state: 'A').count
      report[:premis_events] = self.premis_events.count
      report[:work_items] = WorkItem.with_institution(self.id).count
      report[:average_file_size] = average_file_size
      report[:total_file_size] = self.generic_files.where(state: 'A').sum(:size)
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