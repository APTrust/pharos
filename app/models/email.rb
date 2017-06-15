class Email < ApplicationRecord

  validates :email_type, presence: true
  validate :has_proper_association

  def self.log_fixity_fail(event_identifier)
    email_log = Email.create(email_type: 'fixity', event_identifier: event_identifier)
    email_log.save!
    email_log
  end

  def self.log_restoration(work_item_id)
    email_log = Email.create(email_type: 'restoration', item_id: work_item_id)
    email_log.save!
    email_log
  end

  private

  def has_proper_association
    if self.email_type == 'fixity'
      errors.add(:event_identifier, 'must not be blank for a failed fixity check email') if self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for a failed fixity check email') unless self.item_id.nil?
    elsif self.email_type == 'restoration'
      errors.add(:item_id, 'must not be blank for a restoration notification email') if self.item_id.nil?
      errors.add(:event_identifier, 'must be left blank for a restoration notification email') unless self.event_identifier.nil?
    end
  end
end
