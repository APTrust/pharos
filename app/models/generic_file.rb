class GenericFile < ActiveRecord::Base
  belongs_to :intellectual_object
  has_many :premis_events
  has_many :checksums
  accepts_nested_attributes_for :checksums, allow_destroy: true
  accepts_nested_attributes_for :premis_events, allow_destroy: true

  validates :uri, :size, :file_format, :identifier, presence: true
  validates_uniqueness_of :identifier

  delegate :institution, to: :intellectual_object

  ### Scopes
  scope :created_before, ->(param) { where('generic_files.created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('generic_files.created_at > ?', param) unless param.blank? }
  scope :updated_before, ->(param) { where('generic_files.updated_at < ?', param) unless param.blank? }
  scope :updated_after, ->(param) { where('generic_files.updated_at > ?', param) unless param.blank? }
  scope :with_file_format, ->(param) { where(file_format: param) unless param.blank? }
  scope :with_identifier, ->(param) { where(identifier: param) unless param.blank? }
  scope :with_identifier_like, ->(param) { where('generic_files.identifier like ?', "%#{param}%") unless param.blank? }
  scope :with_institution, ->(param) {
    joins(:intellectual_object)
    .where('intellectual_objects.institution_id = ?', param) unless param.blank?
  }
  scope :with_uri, ->(param) { where(uri: param) unless param.blank? }
  scope :with_uri_like, ->(param) { where('generic_files.uri like ?', "%#{param}%") unless param.blank? }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
  scope :with_access, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.access = ?', param) unless param.blank?
  }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
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

  def self.find_by_identifier(identifier)
    return nil if identifier.blank?
    unescaped_identifier = identifier.gsub(/%2F/i, '/')
    GenericFile.where(identifier: unescaped_identifier).first
  end

  def to_param
    identifier
  end

  def find_latest_fixity_check
    fixity = ''
    latest = self.premis_events.where(event_type: 'fixity_check').order('date_time DESC').first.date_time
    fixity = latest unless latest.nil?
    fixity
  end

  def self.find_files_in_need_of_fixity(date, options={})
    rows = options[:rows] || 10
    start = options[:start] || 0
    files = GenericFile.joins(:premis_events).where('state = ? AND premis_events.event_type = ? AND premis_events.date_time <= ?',
                                                    'A', 'fixity_check', date).order('premis_events.date_time').reverse_order
    files = Kaminari.paginate_array(files).page(start).per(rows)
    files
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

  def soft_delete(attributes)
    user_email = attributes[:outcome_detail]
    attributes[:identifier] = SecureRandom.uuid
    io = IntellectualObject.find(self.intellectual_object_id)
    WorkItem.create_delete_request(io.identifier,
                                        self.identifier,
                                        user_email)
    self.state = 'D'
    self.add_event(attributes)
    save!
  end

  # This is for serializing JSON in the API.
  # Be sure all datetimes are formatted as ISO8601,
  # or some JSON parsers (like the golang parser)
  # will choke on them. The datetimes we pull back
  # from Fedora are strings that are not in ISO8601
  # format, so we have to parse & reformat them.
  def serializable_hash(options={})
    data = {
        id: id,
        uri: uri,
        size: size.to_i,
        created_at: Time.parse(created_at.to_s).iso8601,
        updated_at: Time.parse(updated_at.to_s).iso8601,
        file_format: file_format,
        identifier: identifier,
        intellectual_object_identifier: intellectual_object.identifier,
        state: state,
    }
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
    #checksums.select { |cs| digest.strip == cs.digest.first.to_s.strip }.first
  end

  # Returns true if the GenericFile has a checksum with the specified digest.
  def has_checksum?(digest)
    find_checksum_by_digest(digest).nil? == false
  end

end
