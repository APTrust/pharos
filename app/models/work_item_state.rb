class WorkItemState < ActiveRecord::Base
  require 'zlib'

  belongs_to :work_item
  validates :action, presence: true
  before_save :set_action

  def to_param
    work_item_id
  end

  def serializable_hash (options={})
    #unzipped_state = WorkItemState.inflate(self.state) unless self.state.nil?
    unzipped_state = Zlib::Inflate.inflate(self.state) unless self.state.nil?
    {
        id: id,
        work_item_id: work_item_id,
        action: action,
        state: unzipped_state
    }
  end

  def self.inflate(string)
    zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    buf = zstream.inflate(string)
    zstream.finish
    zstream.close
    buf
  end

  private

  def set_action
    self.action = self.work_item.action if self.action.blank?
  end

end
