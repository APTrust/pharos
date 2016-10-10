class PremisEvent < ActiveRecord::Base

  belongs_to :institution
  belongs_to :intellectual_object
  belongs_to :generic_file

  validates :identifier, :event_type, :date_time, :detail, :outcome, :outcome_detail, :object, :agent, presence: true
  validates_uniqueness_of :identifier

  before_save :init_identifier
  before_save :init_time
  before_save :set_inst_id
  before_save :set_other_identifiers

  ###SCOPES
  scope :with_type, ->(param) { where(event_type: param) unless param.blank? }
  scope :with_event_identifier, ->(param) { where(identifier: param) unless param.blank? }
  scope :with_event_identifier_like, ->(param) { where('premis_events.identifier LIKE ?', "%#{param}%") }
  scope :with_create_date, ->(param) { where(created_at: param) unless param.blank? }
  scope :created_before, ->(param) { where('premis_events.created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('premis_events.created_at >= ?', param) unless param.blank? }
  scope :with_institution, ->(param) { where(institution_id: param) unless param.blank? }
  scope :with_outcome, ->(param) { where(outcome: param) unless param.blank? }
  scope :with_object_identifier, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.identifier = ?', param) unless param.blank?
  }
  scope :with_object_identifier_like, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.identifier LIKE ?', "%#{param}%") unless param.blank?
  }
  scope :with_file_identifier, ->(param) {
    joins(:generic_file)
        .where('generic_files.identifier = ?', param) unless param.blank?
  }
  scope :with_file_identifier_like, ->(param) {
    joins(:generic_file)
        .where('generic_files.identifier LIKE ?', "%#{param}%") unless param.blank?
  }
  scope :with_access, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.access = ?', param) unless param.blank?
  }
  scope :discoverable, ->(current_user) {
    # Any user can discover any item at their institution,
    # along with 'consortia' items from any institution.
    joins(:intellectual_object)
        .where("(intellectual_objects.access = 'consortia' or intellectual_objects.institution_id = ?)", current_user.institution.id) unless current_user.admin?
  }
  scope :readable, ->(current_user) {
    # Inst admin can read anything at their institution.
    # Inst user can read read any unrestricted item at their institution.
    # Admin can read anything.
    if current_user.institutional_admin?
      joins(:intellectual_object)
          .where('intellectual_objects.institution_id = ?', current_user.institution.id)
    elsif current_user.institutional_user?
      joins(:intellectual_object)
          .where("(intellectual_objects.access != 'restricted' and intellectual_objects.institution_id = ?)", current_user.institution.id)
    end
  }
  scope :writable, ->(current_user) {
    # Only admin has write privileges for now.
    where('(1 = 0)') unless current_user.admin?
  }

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
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601,
        id: self.id
    }
    data.merge!(intellectual_object_id: intellectual_object_id) if self.intellectual_object !nil?
    data.merge!(generic_file_id: generic_file_id) if self.generic_file !nil?
    data
  end

  private
  def init_time
    self.date_time = Time.now.utc.iso8601 if self.date_time.nil?
  end

  def init_identifier
    self.identifier = SecureRandom.uuid if self.identifier.nil?
  end

  def set_inst_id
    unless self.intellectual_object.nil?
      self.institution_id = self.intellectual_object.institution.id
    end
  end

  def set_other_identifiers
    if self.intellectual_object_identifier == ''
      self.intellectual_object_identifier = self.intellectual_object.identifier unless self.intellectual_object.nil?
    end
    if self.generic_file_identifier == ''
      self.generic_file_identifier = self.generic_file.identifier unless self.generic_file.nil?
    end
  end

end
