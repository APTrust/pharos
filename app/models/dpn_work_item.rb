class DpnWorkItem < ActiveRecord::Base
  self.primary_key = 'id'
  validates :task, :identifier, presence: true
  validate :task_is_allowed
  validate :status_is_allowed
  validate :stage_is_allowed

  ### Scopes
  scope :with_remote_node, ->(param) { where(remote_node: param) unless param.blank? }
  scope :with_processing_node, ->(param) { where(processing_node: param) unless param.blank? }
  scope :with_task, ->(param) { where(task: param) unless param.blank? }
  scope :with_identifier, ->(param) { where(identifier: param) unless param.blank? }
  scope :with_pid, ->(param) { where(pid: param) unless param.blank? }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
  scope :queued_before, ->(param) { where('dpn_work_items.queued_at < ?', param) unless param.blank? }
  scope :queued_after, ->(param) { where('dpn_work_items.queued_at > ?', param) unless param.blank? }
  scope :completed_before, ->(param) { where('dpn_work_items.completed_at < ?', param) unless param.blank? }
  scope :completed_after, ->(param) { where('dpn_work_items.completed_at > ?', param) unless param.blank? }
  scope :is_completed, ->(param) { where("completed_at is NOT NULL") if param == 'true' }
  scope :is_not_completed, ->(param) { where("completed_at is NULL") if param == 'true' }
  scope :with_stage, ->(param) { where(stage: param) unless param.blank? }
  scope :with_status, ->(param) { where(status: param) unless param.blank? }
  scope :with_retry, ->(param) {
    unless param.blank?
      if param == 'true'
        where(retry: true)
      elsif param == 'false'
        where(retry: false)
      end
    end }
  scope :discoverable, ->(current_user) { where('(1 = 0)') unless current_user.admin? }
  scope :queued, ->(param) {
    unless param.blank?
      if param == 'is_queued'
        where("queued_at is NOT NULL")
      elsif param == 'is_not_queued'
        where("queued_at is NULL")
      end
    end
  }

  # We want this to always be true so that authorization happens in the user policy, preventing incorrect 404 errors.
  scope :readable, ->(current_user) { where('(1=1)') }

  def serializable_hash (options={})
    {
        id: id,
        remote_node: remote_node,
        processing_node: processing_node,
        task: task,
        identifier: identifier,
        queued_at: queued_at,
        completed_at: completed_at,
        note: note,
        state: state,
        stage: stage,
        status: status,
        retry: self.retry,
        pid: pid
    }
  end

  def pretty_state
    return nil if self.state.nil? || self.state.strip == ''
    return JSON.pretty_generate(JSON.parse(self.state))
  end

  def self.stalled_dpn_replications
    DpnWorkItem.queued_before(Time.now - 24.hours).is_not_completed('true').order('queued_at DESC')
  end

  def self.stalled_dpn_replication_count
    DpnWorkItem.stalled_dpn_replications.count
  end

  def requeue_item(delete_state)
    self.pid = 0
    self.state = '' if delete_state == 'true'
    self.save!
  end

  def fixity_requeue(stage)
    self.stage = stage
    self.status = Pharos::Application::PHAROS_STATUSES['pend']
    self.retry = true
    self.pid = 0
    self.processing_node = nil
    self.save!
  end

  private

  def task_is_allowed
    unless Pharos::Application::DPN_TASKS.include?(self.task)
      errors.add(:task, 'Task is not one of the allowed options')
    end
  end

  def status_is_allowed
    unless self.status.nil?
      errors.add(:status, 'Status is not one of the allowed options') unless Pharos::Application::PHAROS_STATUSES.values.include?(self.status)
    end
  end

  def stage_is_allowed
    unless self.stage.nil?
      errors.add(:stage, 'Stage is not one of the allowed options') unless Pharos::Application::PHAROS_STAGES.values.include?(self.stage)
    end
  end
end
