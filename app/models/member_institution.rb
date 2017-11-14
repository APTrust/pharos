class MemberInstitution < Institution
  has_many :subscription_institutions

  def subscribers
    SubscriptionInstitution.where(member_institution_id: self.id)
  end

  def subscriber_report
    si_report = {}
    self.subscribers.each do |si|
      si_report[si.name] = si.generic_files.sum(:size)
    end
    si_report
  end

  def generate_overview
    report = {}
    report[:bytes_by_format] = self.bytes_by_format
    report[:intellectual_objects] = self.intellectual_objects.where(state: 'A').count
    report[:generic_files] = self.generic_files.where(state: 'A').count
    report[:premis_events] = self.premis_events.count
    report[:work_items] = WorkItem.with_institution(self.id).count
    report[:average_file_size] = average_file_size
    report[:subscribers] = self.subscriber_report
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