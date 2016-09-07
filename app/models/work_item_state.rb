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
  # We only look at the first 50 chars, because the full
  # string may be a few megabytes, and the gzip header
  # in the first few bytes will contain binary data.
  def state_looks_like_plaintext
    if state.length <= 50
      sample = state
    else
      last_index = [state.length, 50].min
      sample = state.slice(0, last_index)
    end
    # Regex checks for unprintable characters.
    # If no match, we assume plaintext.
    !sample.match(/[^[:print:]]/)
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
