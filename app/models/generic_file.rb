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
  scope :with_identifier_like, ->(param) { where('generic_files.identifier like ?', "%#{param}%") unless GenericFile.empty_param(param) }
  scope :with_institution, ->(param) {
    joins(:intellectual_object)
    .where('intellectual_objects.institution_id = ?', param) unless param.blank?
  }
  scope :with_uri, ->(param) { where(uri: param) unless param.blank? }
  scope :with_uri_like, ->(param) { where('generic_files.uri like ?', "%#{param}%") unless GenericFile.empty_param(param) }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
  scope :with_access, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.access = ?', param) unless param.blank?
  }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
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
    GenericFile.where(identifier: unescaped_identifier).first
  end

  def to_param
    identifier
  end

  def self.empty_param(param)
    (param.blank? || param.nil? || param == '*' || param == '' || param == '%') ? true : false
  end

  # TODO: event_type names need to match event constants in
  # https://github.com/APTrust/exchange/blob/master/constants/constants.go
  def find_latest_fixity_check
    fixity = ''
    latest = self.premis_events.where(event_type: 'fixity check').order('date_time DESC').first.date_time
    fixity = latest unless latest.nil?
    fixity
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
    self.save!
  end

  # This is for serializing JSON in the API.
  def serializable_hash(options={})
    data = super(options)
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
    #checksums.select { |cs| digest.strip == cs.digest.first.to_s.strip }.first
  end

  # Returns true if the GenericFile has a checksum with the specified digest.
  def has_checksum?(digest)
    find_checksum_by_digest(digest).nil? == false
  end

  # Returns a list of GenericFiles that have not had a fixity
  # check since the specified date. Params limit and offset are
  # integers describing how many records to return and where
  # to start in the result set. Files are ordered by created_at
  # (ascending). Params limit and offset are required because
  # we really don't want to call find on a list of a million ids.
  # Note that this returns active (undeleted) files only.
  # We don't do fixity checks on deleted files.
  def self.not_checked_since(since_when, limit, offset)
    limit = 10 if limit.blank? || limit < 1
    offset ||= 0
    # Get a list of GenericFile ids that have no "fixity check"
    # event since the specified date. Then get the actual GenericFiles
    # with those ids.
    query_template = "select gf.id from generic_files gf where state = 'A' " +
      "and gf.identifier not in " +
      "(select generic_file_identifier from premis_events " +
      "where event_type = 'fixity check' and date_time > :since_when) " +
      "order by gf.created_at asc limit :limit offset :offset"
    safe_query = sanitize_sql([query_template, since_when: since_when, limit: limit, offset: offset])
    query_result = connection.exec_query(safe_query)
    ids = query_result.rows.map { |record| record[0] }
    GenericFile.find(ids)
  end

end
