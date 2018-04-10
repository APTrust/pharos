class DpnWorkItem < ActiveRecord::Base

  validates :task, :identifier, presence: true
  validate :task_is_allowed

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

  private

  def task_is_allowed
    if !Pharos::Application::DPN_TASKS.include?(self.task)
      errors.add(:task, 'Task is not one of the allowed options')
    end
  end
end
