class WorkItem < ActiveRecord::Base
  self.primary_key = 'id'
  paginates_per 10

  belongs_to :institution
  belongs_to :intellectual_object # may be nil
  belongs_to :generic_file        # may be nil
  has_one :work_item_state
  has_and_belongs_to_many :emails

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
  scope :with_bag_date, ->(param1, param2) { where('work_items.bag_date >= ? AND work_items.bag_date < ?', param1, param2) unless param1.blank? || param2.blank? }
  scope :queued_before, ->(param) { where('Work_items.queued_at < ?', param) unless param.blank? }
  scope :with_name, ->(param) { where(name: param) unless param.blank? }
  scope :with_name_like, ->(param) { where('work_items.name like ?', "%#{param}%") unless WorkItem.empty_param(param) }
  scope :with_etag, ->(param) { where(etag: param) unless param.blank? }
  scope :with_etag_like, ->(param) { where('work_items.etag like ?', "%#{param}%") unless WorkItem.empty_param(param) }
  scope :with_object_identifier, ->(param) { where(object_identifier: param) unless param.blank? }
  scope :with_object_identifier_like, ->(param) { where('work_items.object_identifier like ?', "%#{param}%") unless WorkItem.empty_param(param) }
  scope :with_file_identifier, ->(param) { where(generic_file_identifier: param) unless param.blank? }
  scope :with_file_identifier_like, ->(param) { where('work_items.generic_file_identifier like ?', "%#{param}%") unless WorkItem.empty_param(param) }
  scope :with_status, ->(param) { where(status: param) unless param.blank? }
  scope :with_stage, ->(param) { where(stage: param) unless param.blank? }
  scope :with_action, ->(param) { where(action: param) unless param.blank? }
  scope :with_institution, ->(param) { where(institution_id: param) unless param.blank? }
  scope :with_node, ->(param) { where(node: param) unless param.blank? }
  scope :with_pid, ->(param) { where(pid: param) unless param.blank? }
  scope :with_unempty_node, ->(param) { where("node is NOT NULL and node != ''") if param == 'true' }
  scope :with_empty_node, ->(param) { where("node is NULL or node = ''") if param == 'true' }
  scope :with_unempty_pid, ->(param) { where('pid is NOT NULL and pid != 0') if param == 'true' }
  scope :with_empty_pid, ->(param) { where('pid is NULL or pid = 0') if param == 'true' }
  scope :with_retry, ->(param) {
    unless param.blank?
      if param == 'true'
        where(retry: true)
      elsif param == 'false'
        where(retry: false)
      end
    end }
  scope :with_access, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.access = ?', param) unless param.blank?
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

  def self.empty_param(param)
    (param.blank? || param.nil? || param == '*' || param == '' || param == '%') ? true : false
  end

  def serializable_hash(options={})
    data = super(options)
    if self.work_item_state
      data['work_item_state_id'] = self.work_item_state.id
    else
      data['work_item_state_id'] = nil
    end
    data
  end

  def self.pending_action(intellectual_object_identifier)
    item = WorkItem
      .where('object_identifier = ? ' +
             'and status not in (?, ?, ?) ' +
             'and action in (?, ?, ?, ?, ?)',
             intellectual_object_identifier,
             Pharos::Application::PHAROS_STATUSES['success'],
             Pharos::Application::PHAROS_STATUSES['fail'],
             Pharos::Application::PHAROS_STATUSES['cancel'],
             Pharos::Application::PHAROS_ACTIONS['ingest'],
             Pharos::Application::PHAROS_ACTIONS['restore'],
             Pharos::Application::PHAROS_ACTIONS['delete'],
             Pharos::Application::PHAROS_ACTIONS['dpn'],
             Pharos::Application::PHAROS_ACTIONS['glacier_restore'])
      .order('date DESC')
      .limit(1)
      .first
  end

  def self.pending_action_for_file(generic_file_identifier)
    item = WorkItem
               .where('generic_file_identifier = ? ' +
                          'and status not in (?, ?, ?) ' +
                          'and action in (?, ?, ?, ?)',
                      generic_file_identifier,
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

  def requeue_item(options={})
    self.status = Pharos::Application::PHAROS_STATUSES['pend']
    self.retry = true
    self.needs_admin_review = false
    self.node = nil
    self.pid = 0
    self.queued_at = nil
    if self.action == Pharos::Application::PHAROS_ACTIONS['delete']
      self.stage = Pharos::Application::PHAROS_STAGES['requested']
      self.note = 'Delete requested'
      self.outcome = 'Not started'
    elsif self.action == Pharos::Application::PHAROS_ACTIONS['restore']
      self.stage = Pharos::Application::PHAROS_STAGES['requested']
      self.note = 'Restore requested'
      self.work_item_state.delete if self.work_item_state && options[:work_item_state_delete]
    elsif self.action == Pharos::Application::PHAROS_ACTIONS['glacier_restore']
      self.stage = Pharos::Application::PHAROS_STAGES['requested']
      self.note = 'Restore requested'
      self.work_item_state.delete if self.work_item_state && options[:work_item_state_delete]
    elsif self.action == Pharos::Application::PHAROS_ACTIONS['ingest']
      if options[:stage]
        if options[:stage] == Pharos::Application::PHAROS_STAGES['fetch']
          self.stage = Pharos::Application::PHAROS_STAGES['receive']
          self.note = 'Item is pending ingest'
          self.work_item_state.delete if self.work_item_state
        elsif options[:stage] == Pharos::Application::PHAROS_STAGES['store']
          self.stage = Pharos::Application::PHAROS_STAGES['store']
          self.note = 'Item is pending storage'
        elsif options[:stage] == Pharos::Application::PHAROS_STAGES['record']
          self.stage = Pharos::Application::PHAROS_STAGES['record']
          self.note = 'Item is pending record'
        end
      end
    elsif self.action == Pharos::Application::PHAROS_ACTIONS['dpn']
      if options[:stage] == Pharos::Application::PHAROS_STAGES['package']
        self.stage = Pharos::Application::PHAROS_STAGES['requested']
        self.note = 'Requested item be sent to DPN'
        self.work_item_state.delete if self.work_item_state
      elsif options[:stage] == Pharos::Application::PHAROS_STAGES['store']
        self.stage = Pharos::Application::PHAROS_STAGES['store']
        self.note = 'Packaging completed, awaiting storage'
      elsif options[:stage] == Pharos::Application::PHAROS_STAGES['record']
        self.stage = Pharos::Application::PHAROS_STAGES['record']
        self.note = 'Bag copied to long-term storage'
      end
    end
    self.save!
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
        elsif item.action == Pharos::Application::PHAROS_ACTIONS['glacier_restore']
          result = 'glacier restore'
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
    restore_item = WorkItem.finish_restore_request(restore_item, requested_by, item)
    restore_item
  end

  def self.create_glacier_restore_request(intellectual_object_identifier, requested_by)
    item = WorkItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    restore_item = item.dup
    restore_item.action = Pharos::Application::PHAROS_ACTIONS['glacier_restore']
    restore_item = WorkItem.finish_restore_request(restore_item, requested_by, item)
    restore_item
  end

  def self.finish_restore_request(restore_item, requested_by, orig_item)
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
    restore_item.size = orig_item.size
    restore_item.stage_started_at = nil
    restore_item.queued_at = nil
    restore_item.save!
    restore_item
  end

  # Creates a WorkItem record showing that someone has requested
  # restoration of a Generic File. This will eventually go into
  # a queue for the restoration worker process.
  def self.create_restore_request_for_file(generic_file, requested_by)
    item = WorkItem.last_ingested_version(generic_file.intellectual_object.identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    action = Pharos::Application::PHAROS_ACTIONS['restore']
    if generic_file.storage_option != 'Standard'
      action = Pharos::Application::PHAROS_ACTIONS['glacier_restore']
    end
    restore_item = item.dup
    restore_item.generic_file_identifier = generic_file.identifier
    restore_item.action = action
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
    restore_item.size = item.size
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
    dpn_item.size = item.size
    dpn_item.stage_started_at = nil
    dpn_item.queued_at = nil
    dpn_item.save!
    dpn_item
  end

  # Creates a WorkItem record showing that someone has requested
  # deletion of a GenericFile. This will eventually go into a queue for
  # the delete worker process.
  def self.create_delete_request(intellectual_object_identifier, generic_file_identifier, requested_by, inst_app, apt_app)
    item = WorkItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    file = GenericFile.with_identifier(generic_file_identifier).first
    file ? size = file.size : size = 0
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
    delete_item.size = size
    delete_item.stage_started_at = nil
    delete_item.queued_at = nil
    delete_item.inst_approver = inst_app
    delete_item.aptrust_approver = apt_app
    delete_item.save!
    delete_item
  end

  def self.deletion_finished?(intellectual_object_identifier)
    item = WorkItem.with_object_identifier(intellectual_object_identifier)
               .with_action(Pharos::Application::PHAROS_ACTIONS['delete'])
               .with_stage(Pharos::Application::PHAROS_STAGES['resolve'])
               .with_status(Pharos::Application::PHAROS_STATUSES['success']).first
    item.nil? ? result = false : result = true
    result
  end

  def self.deletion_finished_for_file?(generic_file_identifier)
    item = WorkItem.with_file_identifier(generic_file_identifier)
               .with_action(Pharos::Application::PHAROS_ACTIONS['delete'])
               .with_stage(Pharos::Application::PHAROS_STAGES['resolve'])
               .with_status(Pharos::Application::PHAROS_STATUSES['success']).first
    item.nil? ? result = false : result = true
    result
  end

  def self.failed_action(datetime, action, user)
    if user.admin?
      WorkItem.with_action(action)
          .with_status(Pharos::Application::PHAROS_STATUSES['fail'])
          .updated_after(datetime)
    else
      WorkItem.with_action(action)
          .with_status(Pharos::Application::PHAROS_STATUSES['fail'])
          .updated_after(datetime)
          .with_institution(user.institution_id)
    end
  end

  def self.failed_action_count(datetime, action, user)
    WorkItem.failed_action(datetime, action, user).count
  end

  def self.stalled_items(user)
    if user.admin?
      WorkItem.where('queued_at < ? AND (status = ? OR status = ?)', (Time.now - 12.hours),
                     Pharos::Application::PHAROS_STATUSES['pend'], Pharos::Application::PHAROS_STATUSES['start']).order('date DESC')
    else
      WorkItem.where('queued_at < ? AND (status = ? OR status = ?)', (Time.now - 12.hours),
                     Pharos::Application::PHAROS_STATUSES['pend'], Pharos::Application::PHAROS_STATUSES['start'])
                     .with_institution(user.institution_id).order('date DESC')
    end
  end

  def self.stalled_items_count(user)
    WorkItem.stalled_items(user).count
  end

  def status_is_allowed
    errors.add(:status, 'Status is not one of the allowed options') unless Pharos::Application::PHAROS_STATUSES.values.include?(self.status)
  end

  def stage_is_allowed
    errors.add(:stage, 'Stage is not one of the allowed options') unless Pharos::Application::PHAROS_STAGES.values.include?(self.stage)
  end

  def action_is_allowed
    errors.add(:action, 'Action is not one of the allowed options') unless Pharos::Application::PHAROS_ACTIONS.values.include?(self.action)
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
    elsif self.action == ingest && self.stage == clean && self.status == success
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
    if self.intellectual_object_id.blank? && !self.object_identifier.blank?
      # When importing data from Fluctus, we have ~215 items for
      # which Fedora produced no IntellectualObject record, despite
      # saying the items were ingested. In these cases, the query
      # below produces a nil IntellectualObject, followed by an error
      # when accessing the nil object's id. We want to import those records
      # anyway. This problem should not be able to occur in Pharos.
      intel_obj = IntellectualObject.where(identifier: self.object_identifier).first
      self.intellectual_object_id = intel_obj.id unless intel_obj.nil?
    end
    if self.generic_file_id.blank? && !self.generic_file_identifier.blank?
      generic_file = GenericFile.where(identifier: self.generic_file_identifier).first
      self.generic_file_id = generic_file.id unless generic_file.nil?
    end
  end

end
