class IntellectualObject < ActiveRecord::Base
  belongs_to :institution
  has_many :generic_files
  has_many :premis_events
  has_many :checksums, through: :generic_files
  accepts_nested_attributes_for :generic_files, allow_destroy: true
  accepts_nested_attributes_for :premis_events, allow_destroy: true
  accepts_nested_attributes_for :checksums, allow_destroy: true

  validates :title, :institution, :identifier, :access, presence: true
  validates_inclusion_of :access, in: %w(consortia institution restricted), message: "#{:access} is not a valid access", if: :access
  validates_uniqueness_of :identifier

  before_save :set_bag_name
  before_destroy :check_for_associations

  ### Scopes
  scope :created_before, ->(param) { where('intellectual_objects.created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('intellectual_objects.created_at > ?', param) unless param.blank? }
  scope :updated_before, ->(param) { where('intellectual_objects.updated_at < ?', param) unless param.blank? }
  scope :updated_after, ->(param) { where('intellectual_objects.updated_at > ?', param) unless param.blank? }
  scope :with_description, ->(param) { where(description: param) unless param.blank? }
  scope :with_description_like, ->(param) { where('intellectual_objects.description like ?', "%#{param}%") unless param.blank? }
  scope :with_identifier, ->(param) { where(identifier: param) unless param.blank? }
  scope :with_identifier_like, ->(param) { where('intellectual_objects.identifier like ?', "%#{param}%") unless param.blank? }
  scope :with_alt_identifier, ->(param) { where(alt_identifier: param) unless param.blank? }
  scope :with_alt_identifier_like, ->(param) { where('intellectual_objects.alt_identifier like ?', "%#{param}%") unless param.blank? }
  scope :with_institution, ->(param) { where(institution: param) unless param.blank? }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
  scope :with_bag_name, ->(param) { where(bag_name: param) unless param.blank? }
  scope :with_bag_name_like, ->(param) { where('intellectual_objects.bag_name like ?', "%#{param}%") unless param.blank? }
  scope :with_etag, ->(param) { where(etag: param) unless param.blank? }
  scope :with_etag_like, ->(param) { where('intellectual_objects.etag like ?', "%#{param}%") unless param.blank? }
  scope :with_title_like, ->(param) { where('intellectual_objects.title like ?', "%#{param}%") unless param.blank? }
  scope :with_access, ->(param) { where(access: param) unless param.blank? }
  scope :with_file_format, ->(param) {
    joins(:generic_files)
        .where('generic_files.file_format = ?', param) unless param.blank?
  }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }
  scope :discoverable, ->(current_user) {
    # Any user can discover any item at their institution,
    # along with 'consortia' items from any institution.
    where("(intellectual_objects.access = 'consortia' or intellectual_objects.institution_id = ?)", current_user.institution.id) unless current_user.admin?
  }
  scope :readable, ->(current_user) {
    # Inst admin can read anything at their institution.
    # Inst user can read read any unrestricted item at their institution.
    # Admin can read anything.
    if current_user.institutional_admin?
      where(institution: current_user.institution)
    elsif current_user.institutional_user?
      where("(intellectual_objects.access != 'restricted' and intellectual_objects.institution_id = ?)", current_user.institution.id)
    end
  }
  scope :writable, ->(current_user) {
    # Only admin has write privileges for now.
    where('(1 = 0)') unless current_user.admin?
  }

  def self.find_by_identifier(identifier)
    return nil if identifier.blank?
    unescaped_identifier = identifier.gsub(/%2F/i, '/')
    IntellectualObject.where(identifier: unescaped_identifier).first
  end

  def to_param
    identifier
  end

  def bytes_by_format
    stats = self.generic_files.sum(:size)
    if stats
      cross_tab = self.generic_files.group(:file_format).sum(:size)
      cross_tab['all'] = stats
      cross_tab
    else
      {'all' => 0}
    end
  end

  def soft_delete(attributes)
    attributes[:identifier] = SecureRandom.uuid
    self.state = 'D'
    self.add_event(attributes)
    save!
    Thread.new() do
      background_deletion(attributes)
      ActiveRecord::Base.connection.close
    end
  end

  def in_dpn?
    object_in_dpn = false
    dpn = Pharos::Application::PHAROS_ACTIONS['dpn']
    record = Pharos::Application::PHAROS_STAGES['record']
    success = Pharos::Application::PHAROS_STATUSES['success']
    dpn_items = WorkItem.where(object_identifier: self.identifier, action: dpn)
    dpn_items.each do |item|
      if item.stage == record && item.status == success
        object_in_dpn = true
        break
      end
    end
    object_in_dpn
  end

  def background_deletion(attributes)
    generic_files.each do |gf|
      gf.soft_delete(attributes)
    end
    save!
  end

  def gf_count
    generic_files.where(state: 'A').count
  end

  def gf_size
    generic_files.where(state: 'A').sum(:size)
  end

  def active_files
    generic_files.where(state: 'A')
  end

  def serializable_hash (options={})
    last_ingested = self.last_ingested_version
    etag = last_ingested.nil? ? nil : last_ingested.etag
    {
      id: id,
      title: title,
      description: description,
      access: access,
      bag_name: bag_name,
      identifier: identifier,
      state: state,
      alt_identifier: alt_identifier,
      etag: etag,
      in_dpn: in_dpn?,
      dpn_uuid: dpn_uuid,
      file_count: gf_count,
      file_size: gf_size
    }
  end

  # Returns the WorkItem describing the last ingested
  # version of this object.
  def last_ingested_version
    WorkItem.last_ingested_version(self.identifier)
  end

  def add_event(attributes)
    event = self.premis_events.build(attributes)
    event.intellectual_object = self
    event.institution = self.institution
    event.save!
    event
  end

  # Is the user allowed to discover this object?
  def can_discover?(user)
    case access
      when 'consortia'
          true
      when 'institution'
          user.admin? || user.institution_id == institution_id
      when 'restricted'
          user.admin? || (user.institional_admin? && user.institution_id == institution_id)
    end
  end

  # Is the user allowed to read this object?
  def can_read?(user)
    case access
      when 'consortia'
          true
      when 'institution'
          user.admin? || user.institution_id == institution_id
      when 'restricted'
          user.admin? || (user.institional_admin? && user.institution_id == institution_id)
    end
  end

  # Is the user allowed to edit this object?
  def can_edit?(user)
    case access
      when 'consortia'
          user.admin? || user.institution_id == institution_id
      when 'institution'
          user.admin? || (user.institional_admin? && user.institution_id == institution_id)
      when 'restricted'
          user.admin? || (user.institional_admin? && user.institution_id == institution_id)
    end
  end


  private

  def has_right_number_of_checksums(checksum_list)
    checksums_okay = true
    if(checksum_list.nil? || checksum_list.length == 0)
      checksums_okay = false
    else
      algorithms = Array.new
      checksum_list.each do |cs|
        if (algorithms.include? cs)
          checksums_okay = false
        else
          algorithms.push(cs)
        end
      end
    end
    checksums_okay
  end

  def check_for_associations
    # Check for related GenericFiles
    unless generic_file_ids.empty?
      errors[:base] << "Cannot delete #{self.id} because Generic Files are associated with it"
    end
    errors[:base].empty?
  end

  def set_bag_name
    return if self.identifier.nil?
    if (self.bag_name.nil? || self.bag_name == '')
      pieces = self.identifier.split('/')
      i = 1
      while i < pieces.count do
        (i == 1) ? name = pieces[1] : name = "#{name}/#{pieces[i]}"
        i = i+1
      end
      self.bag_name = name
    end
  end

end
