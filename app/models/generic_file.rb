class GenericFile < ActiveRecord::Base
  self.primary_key = 'id'
  belongs_to :intellectual_object
  belongs_to :institution
  has_many :premis_events
  has_many :checksums
  has_one :confirmation_token
  accepts_nested_attributes_for :checksums, allow_destroy: true
  accepts_nested_attributes_for :premis_events, allow_destroy: true

  validates :uri, :size, :file_format, :identifier, :last_fixity_check, :institution_id, :storage_option, presence: true
  validates_uniqueness_of :identifier
  validate :init_institution_id, on: :create
  validate :matching_storage_option, on: :create
  validate :storage_option_is_allowed
  before_save :freeze_institution_id
  before_save :freeze_storage_option

  ### Scopes
  scope :created_before, ->(param) { where('generic_files.created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('generic_files.created_at > ?', param) unless param.blank? }
  scope :updated_before, ->(param) { where('generic_files.updated_at < ?', param) unless param.blank? }
  scope :updated_after, ->(param) { where('generic_files.updated_at > ?', param) unless param.blank? }
  scope :with_file_format, ->(param) { where(file_format: param) unless param.blank? }
  scope :with_identifier, ->(param) { where(identifier: param) unless param.blank? }
  scope :with_identifier_like, ->(param) { where('generic_files.identifier like ?', "%#{param}%") unless GenericFile.empty_param(param) }
  scope :with_institution, ->(param) { where(institution_id: param) unless param.blank? }
  scope :with_uri, ->(param) { where(uri: param) unless param.blank? }
  scope :with_uri_like, ->(param) { where('generic_files.uri like ?', "%#{param}%") unless GenericFile.empty_param(param) }
  scope :not_checked_since, ->(param) { where("last_fixity_check <= ? and generic_files.state='A'", param) unless param.blank? }
  scope :with_state, ->(param) { where(state: param) unless (param.blank? || param == 'all' || param == 'All') }
  scope :with_storage_option, ->(param) { where(storage_option: param) unless param.blank? }
  scope :with_access, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.access = ?', param) unless param.blank?
  }
  scope :discoverable, ->(current_user) {
    joins(:intellectual_object)
        .where('intellectual_objects.institution_id = ?', current_user.institution.id) unless current_user.admin?
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

  def self.find_by_identifier(identifier)
    return nil if identifier.blank?
    unescaped_identifier = identifier.gsub(/%2F/i, '/')
    file = GenericFile.where(identifier: unescaped_identifier).first
    # if file.nil?
    #   #check to see if there's a %3A that got turned into a colon by overeager rails
    #   no_colon_identifier = unescaped_identifier.gsub(/:/, '%3A')
    #   file = GenericFile.where(identifier: no_colon_identifier).first
    # end
    file
  end

  def to_param
    identifier
  end

  def self.empty_param(param)
    (param.blank? || param.nil? || param == '*' || param == '' || param == '%') ? true : false
  end

  def self.bytes_by_format
    stats = GenericFile.sum(:size)
    if stats
      cross_tab = GenericFile.group(:file_format).sum(:size)
      cross_tab['all'] = stats
      cross_tab
    else
      {'all' => 0}
    end

  end

  def display
    identifier
  end

  def institution
    self.intellectual_object.institution
  end

  def soft_delete(attributes)
    user_email = attributes[:requestor]
    attributes[:inst_app] ? inst_app = attributes[:inst_app] : inst_app = nil
    attributes[:apt_app] ? apt_app = attributes[:apt_app] : apt_app = nil
    io = IntellectualObject.find(self.intellectual_object_id)
    WorkItem.create_delete_request(io.identifier,
                                   self.identifier,
                                   user_email, inst_app, apt_app)
    self.save!
  end

  def mark_deleted
    if self.deleted_since_last_ingest?
      self.state = 'D'
      self.save!
    else
      raise 'File cannot be marked deleted without first creating a deletion PREMIS event.'
    end
  end

  # Returns true if Premis events say this item has been deleted.
  def deleted_since_last_ingest?
    last_ingest = self.premis_events.where(event_type: Pharos::Application::PHAROS_EVENT_TYPES['ingest']).order(date_time: :desc).limit(1).first
    last_deletion = self.premis_events.where(event_type: Pharos::Application::PHAROS_EVENT_TYPES['delete']).order(date_time: :desc).limit(1).first
    if !last_ingest.nil? && !last_deletion.nil? && last_deletion.date_time > last_ingest.date_time
      return true
    end
    return false
  end

  # This is for serializing JSON in the API.
  def serializable_hash(options={})
    data = super(options)
    data.delete('ingest_state')
    if options.has_key?(:include) && options[:include].include?(:ingest_state)
      if self.ingest_state.nil?
        data['ingest_state'] = 'null'
      else
        state = JSON.parse(self.ingest_state)
        data.merge!(ingest_state: state)
      end
    end
    data['intellectual_object_identifier'] = self.intellectual_object.identifier
    if options.has_key?(:include)
      data.merge!(checksums: serialize_checksums) if options[:include].include?(:checksums)
      data.merge!(premis_events: serialize_events) if options[:include].include?(:premis_events)
    end
    data
  end

  def serialize_checksums
    checksums.map do |cs|
      cs.serializable_hash
    end
  end

  def add_event(attributes)
    event = self.premis_events.build(attributes)
    event.generic_file = self
    event.intellectual_object = self.intellectual_object
    event.institution = self.intellectual_object.institution
    event.save!
    event
  end

  def serialize_events
    premis_events.map do |event|
      event.serializable_hash
    end
  end

  # Returns the checksum with the specified digest, or nil.
  # No need to specify algorithm, since we're using md5 and sha256,
  # and their digests have different lengths.
  def find_checksum_by_digest(digest)
    checksum = nil
    checksums.each do |cs|
      if cs.digest == digest
        checksum = cs
        break
      end
    end
    checksum
  end

  # Returns true if the GenericFile has a checksum with the specified digest.
  def has_checksum?(digest)
    find_checksum_by_digest(digest).nil? == false
  end

  private

  def init_institution_id
    unless self.intellectual_object.nil?
      self.institution_id = self.intellectual_object.institution_id if self.institution_id.nil?
    end
  end

  def matching_storage_option
    unless self.intellectual_object.nil?
      self.storage_option = self.intellectual_object.storage_option
    end
  end

  def freeze_institution_id
    errors.add(:institution_id, 'cannot be changed') if self.institution_id_changed? unless self.institution_id.nil?
  end

  def freeze_storage_option
    errors.add(:storage_option, 'cannot be changed') if self.storage_option_changed? unless self.storage_option.nil?
  end

  def storage_option_is_allowed
    unless Pharos::Application::PHAROS_STORAGE_OPTIONS.include?(self.storage_option)
      errors.add(:storage_option, 'Storage Option is not one of the allowed options')
    end
  end

end
