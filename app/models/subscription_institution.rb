class SubscriptionInstitution  < Institution
  belongs_to :member_institution

  validate :has_associated_member_institution

  private

  def has_associated_member_institution
    errors.add(:member_institution_id, 'cannot be nil') if self.member_institution_id.nil?
  end

end