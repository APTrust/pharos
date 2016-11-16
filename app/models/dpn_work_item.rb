class DpnWorkItem < ActiveRecord::Base

  validates :task, :identifier, presence: true
  validate :task_is_allowed

  ### Scopes
  scope :with_remote_node, ->(param) { where(remote_node: param) unless param.blank? }
  scope :with_task, ->(param) { where(task: param) unless param.blank? }
  scope :with_identifier, ->(param) { where(identifier: param) unless param.blank? }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
  scope :queued_before, ->(param) { where('dpn_work_items.queued_at < ?', param) unless param.blank? }
  scope :queued_after, ->(param) { where('dpn_work_items.queued_at > ?', param) unless param.blank? }
  scope :completed_before, ->(param) { where('dpn_work_items.completed_at < ?', param) unless param.blank? }
  scope :completed_after, ->(param) { where('dpn_work_items.completed_at > ?', param) unless param.blank? }

  def serializable_hash (options={})
    {
        id: id,
        remote_node: remote_node,
        task: task,
        identifier: identifier,
        queued_at: queued_at,
        completed_at: completed_at,
        note: note,
        state: state
    }
  end

  private

  def task_is_allowed
    if !Pharos::Application::DPN_TASKS.include?(self.task)
      errors.add(:task, 'Task is not one of the allowed options')
    end
  end
end
