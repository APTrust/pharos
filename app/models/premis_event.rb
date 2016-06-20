class PremisEvent < ActiveRecord::Base

  belongs_to :intellectual_object
  belongs_to :generic_file

  validates :identifier,  presence: true
  validates :event_type,  presence: true
  validates :date_time,  presence: true
  validates :detail,  presence: true
  validates :outcome,  presence: true
  validates :outcome_detail,  presence: true
  validates :object,  presence: true
  validates :agent,  presence: true

  before_save :init_identifier
  before_save :init_time

  # def initialize(graph={}, subject=nil)
  #   super
  #   init_identifier
  #   init_time
  # end

  def to_param
    identifier
  end

  def serializable_hash
    data = {
        identifier: identifier,
        event_type: event_type,
        date_time: Time.parse(date_time).iso8601,
        detail: detail,
        outcome: outcome,
        outcome_detail: outcome_detail,
        object: object,
        agent: agent,
        outcome_information: outcome_information,
        created_at: created_at,
        updated_at: updated_at
    }
    data.merge!(intellectual_object: intellectual_object_id) if self.intellectual_object !nil?
    data.merge!(generic_file: generic_file_id) if self.generic_file !nil?
    data
  end

  private
  def init_time
    self.date_time = Time.now.utc.iso8601 if self.date_time.nil?
  end

  def init_identifier
    self.identifier = SecureRandom.uuid if self.identifier.nil?
  end

end
