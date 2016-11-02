class WorkItem < ActiveRecord::Base

  paginates_per 10

  belongs_to :institution
  belongs_to :intellectual_object # may be nil
  belongs_to :generic_file        # may be nil
  has_one :work_item_state
  validates :name, :etag, :bag_date, :bucket, :user, :institution, :date, :note, :action, :stage, :status, :outcome, presence: true
  validate :status_is_allowed
  validate :stage_is_allowed
  validate :action_is_allowed
  before_save :set_object_identifier_if_ingested

  ### Scopes
  scope :created_before, ->(param) { where('work_items.created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('work_items.created_at >= ?', param) unless param.blank? }
  scope :updated_before, ->(param) { where('work_items.updated_at < ?', param) unless param.blank? }
  scope :updated_after, ->(param) { where('work_items.updated_at >= ?', param) unless param.blank? }
  scope :with_bag_date, ->(param) { where('work_items.bag_date = ?', param) unless param.blank? }
  scope :with_name, ->(param) { where(name: param) unless param.blank? }
  scope :with_name_like, ->(param) { where('work_items.name like ?', "%#{param}%") unless param.blank? }
  scope :with_etag, ->(param) { where(etag: param) unless param.blank? }
  scope :with_etag_like, ->(param) { where('work_items.etag like ?', "%#{param}%") unless param.blank? }
  scope :with_object_identifier, ->(param) { where(object_identifier: param) unless param.blank? }
  scope :with_object_identifier_like, ->(param) { where('work_items.object_identifier like ?', "%#{param}%") unless param.blank? }
  scope :with_file_identifier, ->(param) { where(generic_file_identifier: param) unless param.blank? }
  scope :with_file_identifier_like, ->(param) { where('work_items.generic_file_identifier like ?', "%#{param}%") unless param.blank? }
  scope :with_status, ->(param) { where(status: param) unless param.blank? }
  scope :with_stage, ->(param) { where(stage: param) unless param.blank? }
  scope :with_action, ->(param) { where(action: param) unless param.blank? }
  scope :with_institution, ->(param) { where(institution_id: param) unless param.blank? }
  scope :with_access, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.access = ?', param) unless param.blank?
  }
  scope :with_state, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.state = ?', param) unless param.blank?
  }
  # We can't always check the permissions on the related IntellectualObject,
  # because some work items (such as in-progress Ingest items) have no object.
  # So for now, users can view work items belonging to their institutions.
  # The WorkItem does not give away info about title or description, only the
  # name of the bag/tar file, which is usually an opaque identifier.
  scope :readable, ->(current_user) {
    where(institution: current_user.institution) unless current_user.admin?
  }
  # queued returns items that have or have not been queued
  scope :queued, ->(param) {
    if !param.blank?
      if param == "false"
        where("queued_at is null")
      elsif param == "true"
        where("queued_at is not null")
      end
    end
    }


  def to_param
    "#{etag}/#{name}"
  end

  def self.pending_action(intellectual_object_identifier)
    item = WorkItem
      .where('object_identifier = ? ' +
             'and status not in (?, ?, ?) ' +
             'and action in (?, ?, ?, ?)',
             intellectual_object_identifier,
             Pharos::Application::PHAROS_STATUSES['success'],
             Pharos::Application::PHAROS_STATUSES['fail'],
             Pharos::Application::PHAROS_STATUSES['cancel'],
             Pharos::Application::PHAROS_ACTIONS['ingest'],
             Pharos::Application::PHAROS_ACTIONS['restore'],
             Pharos::Application::PHAROS_ACTIONS['delete'],
             Pharos::Application::PHAROS_ACTIONS['dpn'])
      .order('date DESC')
      .limit(1)
      .first
  end

  def self.can_delete_file?(intellectual_object_identifier, generic_file_identifier)
    items = WorkItem.where(object_identifier: intellectual_object_identifier)
    items = items.order('date DESC')
    result = 'true'
    items.each do |item|
      if item.status == Pharos::Application::PHAROS_STATUSES['success'] ||
          item.status == Pharos::Application::PHAROS_STATUSES['fail'] ||
          item.status == Pharos::Application::PHAROS_STATUSES['cancel']
        result = 'true'
      else
        if item.action == Pharos::Application::PHAROS_ACTIONS['ingest']
          result = 'ingest'
          break
        elsif item.action == Pharos::Application::PHAROS_ACTIONS['restore']
          result = 'restore'
          break
        elsif item.action == Pharos::Application::PHAROS_ACTIONS['delete'] && item.generic_file_identifier == generic_file_identifier
          result = 'delete'
          break
        end
      end
    end
    result
  end

  # Returns the WorkItem record for the last successfully ingested
  # version of an intellectual object. The last ingested version has
  # these characteristicts:
  #
  # * Action is Ingest
  # * Stage is Clean or (Stage is Record and Status is Success)
  # * Has the latest date of any record with the above characteristics
  def self.last_ingested_version(intellectual_object_identifier)
    conditions = "object_identifier = ? and action = 'Ingest' and " +
      "(stage = 'Record' or stage = 'Cleanup') and status = 'Success'"
    WorkItem.where(conditions, intellectual_object_identifier).order('date DESC').first
  end

  # Creates a WorkItem record showing that someone has requested
  # restoration of an IntellectualObject. This will eventually go into
  # a queue for the restoration worker process.
  def self.create_restore_request(intellectual_object_identifier, requested_by)
    item = WorkItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    restore_item = item.dup
    restore_item.action = Pharos::Application::PHAROS_ACTIONS['restore']
    restore_item.stage = Pharos::Application::PHAROS_STAGES['requested']
    restore_item.status = Pharos::Application::PHAROS_STATUSES['pend']
    restore_item.note = 'Restore requested'
    restore_item.outcome = 'Not started'
    restore_item.user = requested_by
    restore_item.retry = true
    restore_item.date = Time.now
    restore_item.work_item_state.state = nil unless restore_item.work_item_state.nil?
    restore_item.node = nil
    restore_item.pid = 0
    restore_item.needs_admin_review = false
    restore_item.size = nil
    restore_item.stage_started_at = nil
    restore_item.queued_at = nil
    restore_item.save!
    restore_item
  end

  def self.create_dpn_request(intellectual_object_identifier, requested_by)
    item = WorkItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    dpn_item = item.dup
    dpn_item.action = Pharos::Application::PHAROS_ACTIONS['dpn']
    dpn_item.stage = Pharos::Application::PHAROS_STAGES['requested']
    dpn_item.status = Pharos::Application::PHAROS_STATUSES['pend']
    dpn_item.note = 'Requested item be sent to DPN'
    dpn_item.outcome = 'Not started'
    dpn_item.user = requested_by
    dpn_item.retry = true
    dpn_item.date = Time.now
    dpn_item.work_item_state.state = nil unless dpn_item.work_item_state.nil?
    dpn_item.node = nil
    dpn_item.pid = 0
    dpn_item.needs_admin_review = false
    dpn_item.size = nil
    dpn_item.stage_started_at = nil
    dpn_item.queued_at = nil
    dpn_item.save!
    dpn_item
  end

  # Creates a WorkItem record showing that someone has requested
  # deletion of a GenericFile. This will eventually go into a queue for
  # the delete worker process.
  def self.create_delete_request(intellectual_object_identifier, generic_file_identifier, requested_by)
    item = WorkItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    delete_item = item.dup
    delete_item.action = Pharos::Application::PHAROS_ACTIONS['delete']
    delete_item.stage = Pharos::Application::PHAROS_STAGES['requested']
    delete_item.status = Pharos::Application::PHAROS_STATUSES['pend']
    delete_item.note = 'Delete requested'
    delete_item.outcome = 'Not started'
    delete_item.user = requested_by
    delete_item.retry = true
    delete_item.date = Time.now
    delete_item.generic_file_identifier = generic_file_identifier
    delete_item.work_item_state.state = nil unless delete_item.work_item_state.nil?
    delete_item.node = nil
    delete_item.pid = 0
    delete_item.needs_admin_review = false
    delete_item.size = nil
    delete_item.stage_started_at = nil
    delete_item.queued_at = nil
    delete_item.save!
    delete_item
  end

  def status_is_allowed
    if !Pharos::Application::PHAROS_STATUSES.values.include?(self.status)
      errors.add(:status, 'Status is not one of the allowed options')
    end
  end

  def stage_is_allowed
    if !Pharos::Application::PHAROS_STAGES.values.include?(self.stage)
      errors.add(:stage, 'Stage is not one of the allowed options')
    end
  end

  def action_is_allowed
    if !Pharos::Application::PHAROS_ACTIONS.values.include?(self.action)
      errors.add(:action, 'Action is not one of the allowed options')
    end
  end

  # :state may contain a blob of JSON text from our micorservices.
  # If it does, it's stored without extra whitespace, but we want
  # to display it in a readable format.
  def pretty_state
    state_item = self.work_item_state
    unzipped_state = state_item.unzipped_state unless state_item.nil? || state_item.state.nil?
    return nil if unzipped_state.nil? || unzipped_state.strip == ''
    return JSON.pretty_generate(JSON.parse(unzipped_state))
  end

  def ingested?
    ingest = Pharos::Application::PHAROS_ACTIONS['ingest']
    record = Pharos::Application::PHAROS_STAGES['record']
    clean = Pharos::Application::PHAROS_STAGES['clean']
    success = Pharos::Application::PHAROS_STATUSES['success']

    if self.action.blank? == false && self.action != ingest
      # we're past ingest
      return true
    elsif self.action == ingest && self.stage == record && self.status == success
      # we just finished successful ingest
      return true
    elsif self.action == ingest && self.stage == clean
      # we finished ingest and processor is cleaning up
      return true
    end
    # if we get here, we're in some stage of the ingest process,
    # but ingest is not yet complete
    return false
  end

  private

  # WorkItem will not have an object identifier until
  # it has been ingested.
  def set_object_identifier_if_ingested
    if self.object_identifier.blank? && self.ingested?
      # Suffixes for single-part and multi-part bags
      re_single = /\.tar$/
      re_multi = /\.b\d+\.of\d+$/
      bag_basename = self.name.sub(re_single, '').sub(re_multi, '')
      self.object_identifier = "#{self.institution.identifier}/#{bag_basename}"
    end
    unless self.object_identifier.blank?
      self.intellectual_object_id = IntellectualObject.where(identifier: self.object_identifier).first.id
    end
    unless self.generic_file_identifier.blank?
      self.generic_file_id = GenericFile.where(identifier: self.generic_file_identifier).first.id
    end
  end

end
