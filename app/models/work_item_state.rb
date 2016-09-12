class WorkItemState < ActiveRecord::Base
  require 'zlib'

  belongs_to :work_item
  validates :action, presence: true
  before_save :set_action, :compress_state

  def to_param
    work_item_id
  end

  def serializable_hash (options={})
    {
        id: id,
        work_item_id: work_item_id,
        action: action,
        state: self.unzipped_state
    }
  end

  def unzipped_state
    if state.blank? || state_looks_like_plaintext
      state
    else
      Zlib::Inflate.inflate(state)
    end
  end

  private

  # Returns true if state looks like plaintext.
  # Since our plaintext should always be JSON data,
  # we'll do a simple test for opening and closing
  # braces.
  def state_looks_like_plaintext
    state.start_with?('{') && state.end_with?('}')
  end

  def set_action
    self.action = self.work_item.action if self.action.blank?
  end

  # Compress the state field, if it's not already compressed
  def compress_state
    if !state.blank? && state_looks_like_plaintext
      self.state = Zlib::Deflate.deflate(state)
    end
  end

end
