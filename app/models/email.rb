class Email < ApplicationRecord
  self.primary_key = 'id'
  has_and_belongs_to_many :premis_events
  has_and_belongs_to_many :work_items
  has_and_belongs_to_many :intellectual_objects
  has_and_belongs_to_many :generic_files

  validates :email_type, presence: true
  validate :has_proper_association

  def self.log_fixity_fail(event_identifier)
    email_log = Email.create(email_type: 'fixity', event_identifier: event_identifier)
    email_log.save!
    email_log
  end

  def self.log_multiple_fixity_fail(events)
    email_log = Email.create(email_type: 'multiple_fixity')
    events.each { |event| event.emails.push(email_log) }
    if email_log.premis_events.count == events.count
      email_log.save!
      email_log
    else
      throw(:abort)
    end
  end

  def self.log_restoration(work_item_id)
    email_log = Email.create(email_type: 'restoration', item_id: work_item_id)
    email_log.save!
    email_log
  end

  def self.log_multiple_restoration(work_items)
    email_log = Email.create(email_type: 'multiple_restoration')
    work_items.each { |item| item.emails.push(email_log) }
    if email_log.work_items.count == work_items.count
      email_log.save!
      email_log
    else
      throw(:abort)
    end
  end

  def self.log_deletion_request(deletion_subject)
    if deletion_subject.is_a?(IntellectualObject)
      email_log = Email.create(email_type: 'deletion_request', intellectual_object_id: deletion_subject.id)
    elsif deletion_subject.is_a?(GenericFile)
      email_log = Email.create(email_type: 'deletion_request', generic_file_id: deletion_subject.id)
    elsif deletion_subject.is_a?(Institution)
      email_log = Email.create(email_type: 'bulk_deletion_request', institution_id: deletion_subject.id)
    end
    email_log.save!
    email_log
  end

  def self.log_deletion_confirmation(deletion_subject)
    if deletion_subject.is_a?(IntellectualObject)
      email_log = Email.create(email_type: 'deletion_confirmation', intellectual_object_id: deletion_subject.id)
    elsif deletion_subject.is_a?(GenericFile)
      email_log = Email.create(email_type: 'deletion_confirmation', generic_file_id: deletion_subject.id)
    end
    email_log.save!
    email_log
  end

  def self.log_bulk_deletion_confirmation(deletion_subject, step)
    if step == 'partial'
      email_log = Email.create(email_type: 'bulk_deletion_confirmation_partial', institution_id: deletion_subject.id)
    elsif step == 'final'
      email_log = Email.create(email_type: 'bulk_deletion_confirmation_final', institution_id: deletion_subject.id)
    end
    email_log.save!
    email_log
  end

  def self.log_deletion_finished(deletion_subject)
    if deletion_subject.is_a?(IntellectualObject)
      email_log = Email.create(email_type: 'deletion_finished', intellectual_object_id: deletion_subject.id)
    elsif deletion_subject.is_a?(GenericFile)
      email_log = Email.create(email_type: 'deletion_finished', generic_file_id: deletion_subject.id)
    elsif deletion_subject.is_a?(Institution)
      email_log = Email.create(email_type: 'bulk_deletion_finished', institution_id: deletion_subject.id)
    end
    email_log.save!
    email_log
  end

  def self.log_daily_deletion_notification(deletion_subject)
    email_log = Email.create(email_type: 'deletion_notifications', institution_id: deletion_subject.id)
    email_log.save!
    email_log
  end

  private

  def has_proper_association
    if self.email_type == 'fixity'
      errors.add(:event_identifier, 'must not be blank for a failed fixity check email') if self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for a failed fixity check email') unless self.item_id.nil?
      errors.add(:intellectual_object_id, 'must be left blank for a failed fixity check email') unless self.intellectual_object_id.nil?
      errors.add(:generic_file_id, 'must be left blank for a failed fixity check email') unless self.generic_file_id.nil?
      errors.add(:institution_id, 'must be left blank for a failed fixity check email') unless self.institution_id.nil?
    elsif self.email_type == 'restoration'
      errors.add(:item_id, 'must not be blank for a restoration notification email') if self.item_id.nil?
      errors.add(:event_identifier, 'must be left blank for a restoration notification email') unless self.event_identifier.nil?
      errors.add(:intellectual_object_id, 'must be left blank for a restoration notification email') unless self.intellectual_object_id.nil?
      errors.add(:generic_file_id, 'must be left blank for a restoration notification email') unless self.generic_file_id.nil?
      errors.add(:institution_id, 'must be left blank for a restoration notification email') unless self.institution_id.nil?
    elsif self.email_type == 'multiple_fixity'
      errors.add(:work_items, 'must be empty for a failed fixity check email') if self.work_items.count != 0
      errors.add(:intellectual_object_id, 'must be left blank for a failed fixity check email') unless self.intellectual_object_id.nil?
      errors.add(:generic_file_id, 'must be left blank for a failed fixity check email') unless self.generic_file_id.nil?
      errors.add(:institution_id, 'must be left blank for a failed fixity check email') unless self.institution_id.nil?
    elsif self.email_type == 'multiple_restoration'
      errors.add(:premis_events, 'must be empty for a restoration notification email') if self.premis_events.count != 0
      errors.add(:intellectual_object_id, 'must be left blank for a restoration notification email') unless self.intellectual_object_id.nil?
      errors.add(:generic_file_id, 'must be left blank for a restoration notification email') unless self.generic_file_id.nil?
      errors.add(:institution_id, 'must be left blank for a restoration notification email') unless self.institution_id.nil?
    elsif self.email_type == 'deletion_request'
      if self.intellectual_object_id.nil? && self.generic_file_id.nil?
        errors.add(:intellectual_object_id, 'or generic_file_id must be present for a deletion request email')
        errors.add(:generic_file_id, 'or intellectual_object_id must be present for a deletion request email')
      end
      errors.add(:event_identifier, 'must be left blank for a deletion request email') unless self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for a deletion request email') unless self.item_id.nil?
      errors.add(:work_items, 'must be empty for a deletion request email') if self.work_items.count != 0
      errors.add(:premis_events, 'must be empty for a deletion request email') if self.premis_events.count != 0
      errors.add(:institution_id, 'must be left blank for a single deletion request email') unless self.institution_id.nil?
    elsif self.email_type == 'deletion_confirmation'
      if self.intellectual_object_id.nil? && self.generic_file_id.nil?
        errors.add(:intellectual_object_id, 'or generic_file_id must be present for a deletion confirmation email')
        errors.add(:generic_file_id, 'or intellectual_object_id must be present for a deletion confirmation email')
      end
      errors.add(:event_identifier, 'must be left blank for a deletion confirmation email') unless self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for a deletion confirmation email') unless self.item_id.nil?
      errors.add(:work_items, 'must be empty for a deletion confirmation email') if self.work_items.count != 0
      errors.add(:premis_events, 'must be empty for a deletion confirmation email') if self.premis_events.count != 0
      errors.add(:institution_id, 'must be left blank for a single deletion confirmation email') unless self.institution_id.nil?
    elsif self.email_type == 'deletion_finished'
      if self.intellectual_object_id.nil? && self.generic_file_id.nil?
        errors.add(:intellectual_object_id, 'or generic_file_id must be present for a finished deletion email')
        errors.add(:generic_file_id, 'or intellectual_object_id must be present for a finished deletion email')
      end
      errors.add(:event_identifier, 'must be left blank for a finished deletion email') unless self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for a finished deletion email') unless self.item_id.nil?
      errors.add(:work_items, 'must be empty for a finished deletion email') if self.work_items.count != 0
      errors.add(:premis_events, 'must be empty for a finished deletion email') if self.premis_events.count != 0
      errors.add(:institution_id, 'must be left blank for a single finished deletion email') unless self.institution_id.nil?
    elsif self.email_type == 'bulk_deletion_request'
      errors.add(:institution_id, 'must not be left blank for a bulk deletion request email') if self.institution_id.nil?
      errors.add(:event_identifier, 'must be left blank for a bulk deletion request email') unless self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for a bulk deletion request email') unless self.item_id.nil?
      errors.add(:intellectual_object_id, 'must be left blank for a bulk deletion request email') unless self.intellectual_object_id.nil?
      errors.add(:generic_file_id, 'must be left blank for a bulk deletion request email') unless self.generic_file_id.nil?
      errors.add(:work_items, 'must be empty for a bulk deletion request email') if self.work_items.count != 0
      errors.add(:premis_events, 'must be empty for a bulk deletion request email') if self.premis_events.count != 0
    elsif self.email_type == 'bulk_deletion_finished'
      errors.add(:institution_id, 'must not be left blank for a finished bulk deletion email') if self.institution_id.nil?
      errors.add(:event_identifier, 'must be left blank for a finished bulk deletion email') unless self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for a finished bulk deletion email') unless self.item_id.nil?
      errors.add(:intellectual_object_id, 'must be left blank for a finished bulk deletion email') unless self.intellectual_object_id.nil?
      errors.add(:generic_file_id, 'must be left blank for finished a bulk deletion email') unless self.generic_file_id.nil?
      errors.add(:work_items, 'must be empty for a finished bulk deletion email') if self.work_items.count != 0
      errors.add(:premis_events, 'must be empty for a finished bulk deletion email') if self.premis_events.count != 0
    elsif self.email_type == 'bulk_deletion_confirmation_partial' || self.email_type == 'bulk_deletion_confirmation_final' || self.email_type == 'deletion_notification'
      errors.add(:institution_id, 'must not be left blank for a bulk deletion confirmation or deletion notification email') if self.institution_id.nil?
      errors.add(:event_identifier, 'must be left blank for bulk deletion confirmation and deletion notification emails') unless self.event_identifier.nil?
      errors.add(:item_id, 'must be left blank for bulk deletion confirmation and deletion notification emails') unless self.item_id.nil?
      errors.add(:intellectual_object_id, 'must be left blank for bulk deletion confirmation and deletion notification emails') unless self.intellectual_object_id.nil?
      errors.add(:generic_file_id, 'must be left blank for bulk deletion confirmation and deletion notification emails') unless self.generic_file_id.nil?
      errors.add(:work_items, 'must be left blank for bulk deletion confirmation and deletion notification emails') if self.work_items.count != 0
      errors.add(:premis_events, 'must be left blank for bulk deletion confirmation and deletion notification emails') if self.premis_events.count != 0
    end
  end
end
