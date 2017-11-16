class SubscriptionInstitution  < Institution
  belongs_to :member_institution

  validate :has_associated_member_institution

  def generate_overview
    report = {}
    report[:bytes_by_format] = self.bytes_by_format
    report[:intellectual_objects] = self.intellectual_objects.where(state: 'A').count
    report[:generic_files] = self.generic_files.where(state: 'A').count
    report[:premis_events] = self.premis_events.count
    report[:work_items] = WorkItem.with_institution(self.id).count
    report[:average_file_size] = average_file_size
    report
  end

  private

  def has_associated_member_institution
    errors.add(:member_institution_id, 'cannot be nil') if self.member_institution_id.nil?
  end

end