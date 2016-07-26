class IntellectualObject < ActiveRecord::Base
  #include Auditable   # premis events

  belongs_to :institution
  has_many :generic_files
  has_many :premis_events
  has_many :checksums, through: :generic_files
  accepts_nested_attributes_for :generic_files, allow_destroy: true, reject_if: :invalid_file
  accepts_nested_attributes_for :premis_events, allow_destroy: true
  accepts_nested_attributes_for :checksums, allow_destroy: true

  validates :title, presence: true
  validates :institution, presence: true
  validates :identifier, presence: true
  validates :access, presence: true
  validates_inclusion_of :access, in: %w(consortia institution restricted), message: "#{:access} is not a valid access", if: :access
  validate :identifier_is_unique

  before_save :set_bag_name
  before_save :set_permissions
  before_save :active_files
  before_destroy :check_for_associations


  ### Scopes
  scope :created_before, ->(param) { where("created_at < ?", param) unless param.blank? }
  scope :created_after, ->(param) { where("created_at > ?", param) unless param.blank? }
  scope :updated_before, ->(param) { where("updated_at < ?", param) unless param.blank? }
  scope :updated_after, ->(param) { where("updated_at > ?", param) unless param.blank? }
  scope :with_description, ->(param) { where(description: param) unless param.blank? }
  scope :with_description_like, ->(param) { where("description like ?", "%#{param}%") unless param.blank? }
  scope :with_identifier, ->(param) { where(identifier: param) unless param.blank? }
  scope :with_identifier_like, ->(param) { where("identifier like ?", "%#{param}%") unless param.blank? }
  scope :with_alt_identifier, ->(param) { where(alt_identifier: param) unless param.blank? }
  scope :with_alt_identifier_like, ->(param) { where("alt_identifier like ?", "%#{param}%") unless param.blank? }
  scope :with_institution, ->(param) { where(institution: param) unless param.blank? }
  scope :with_state, ->(param) { where(state: param) unless param.blank? }

  # Param for discoverable should be current_user!
  scope :discoverable, ->(current_user) {
    # Any user can discover any item at their institution,
    # along with 'consortia' items from any institution.
    where("(access = 'consortia' or institution = ?)", current_user.institution) unless current_user.admin?
  }
  scope :readable, ->(current_user) {
    # Inst admin can read anything at their institution.
    # Inst user can read read any unrestricted item at their institution.
    # Admin can read anything.
    if current_user.institutional_admin?
      where("institution = ?", current_user.institution)
    elsif current_user.institutional_user?
      where("(access != 'restricted' and institution = ?)", current_user.institution)
    end
  }
  scope :writable, ->(current_user) {
    # Inst admin can write anything at their institution.
    # Inst user can write read any unrestricted item at their institution.
    # Admin can read anything.
    if current_user.institutional_admin?
      where("(access != 'restricted' and institution = ?)", current_user.institution)
    elsif current_user.institutional_user?
      # This will ALWAYS be false, meaning inst user can't edit anything.
      # Is that what we want?
      where("(1 = 0)")
    end
  }



  # Need to add these...
  #scope :bag_name, ->(param) {}
  #scope :etag, ->(param) {}

  def to_param
    identifier
  end

  # TODO: Can we get rid of this?
  # Doesn't Rails automatically call validate on each file object before saving?
  def invalid_file(attributes)
    file_valid = true
    file_valid = false if (attributes['uri'].nil? || attributes['uri'] == '')
    file_valid = false if (attributes['size'].nil? || attributes['size'] == '')
    file_valid = false if (attributes['created'].nil? || attributes['created'] == '')
    file_valid = false if (attributes['modified'].nil? || attributes['modified'] == '')
    file_valid = false if (attributes['file_format'].nil? || attributes['file_format'] == '')
    file_valid = false if (attributes['identifier'].nil? || attributes['identifier'] == '')
    checksums = has_right_number_of_checksums(attributes['checksums_attributes'])
    file_valid = false if !checksums
    file_valid = false if !unique_file_identifier(attributes)
    !file_valid
  end

  def institution_identifier
    inst = self.identifier.split('/')
    inst[0]
  end

  # This governs which fields show up on the editor. This is part of the expected interface for hydra-editor
  def terms_for_editing
    [:title, :description, :access]
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
    # TODO: Add etag and DPN bag UUID to the IntelObj table
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
      alt_identifier: [alt_identifier],
      etag: etag,
      in_dpn: in_dpn?,
      file_count: gf_count,
      file_size: gf_size
    }
  end

  # Returns the WorkItem describing the last ingested
  # version of this object.
  def last_ingested_version
    WorkItem.last_ingested_version(self.identifier)
  end

  # # This is for serializing JSON in the API.
  # def serializable_hash(options={})
  #   data = {
  #       id: id,
  #       title: title,
  #       description: description,
  #       access: access,
  #       bag_name: bag_name,
  #       identifier: identifier,
  #       state: state,
  #   }
  #   data.merge!(alt_identifier: serialize_alt_identifiers)
  #   if options.has_key?(:include)
  #     options[:include].each do |opt|
  #       if opt.is_a?(Hash) && opt.has_key?(:active_files)
  #         data.merge!(active_files: serialize_active_files(opt[:active_files]))
  #       end
  #     end
  #     data.merge!(premis_events: serialize_events) if options[:include].include?(:premis_events)
  #     if options[:include].include?(:etag)
  #       item = WorkItem.last_ingested_version(self.identifier)
  #       data.merge!(etag: item.etag) unless item.nil?
  #     end
  #   end
  #   data
  # end

  # def serialize_active_files(options={})
  #   self.active_files.map do |file|
  #     file.serializable_hash(options)
  #   end
  # end

  def add_event(attributes)
    event = self.premis_events.build(attributes)
    event.intellectual_object = self
    event.save!
    event
  end

  # def serialize_events
  #   self.premis_events.map do |event|
  #     event.serializable_hash
  #   end
  # end

  # def serialize_alt_identifiers
  #   data = []
  #   alts = alt_identifier.split(',') unless alt_identifier.nil?
  #   unless alts.nil?
  #     alts.each do |ident|
  #       data.push(ident)
  #     end
  #   end
  #   data
  # end

  def set_permissions
    inst_id = self.institution.id
    inst_admin_group = "Admin_At_#{inst_id}"
    inst_user_group = "User_At_#{inst_id}"
    permissions = {}
    case access
      when 'consortia'
        permissions[:discover_groups] = %w(admin institutional_admin institutional_user)
        permissions[:read_groups] = %w(admin institutional_admin institutional_user)
        permissions[:edit_groups] = ['admin', inst_admin_group]
      when 'institution'
        permissions[:discover_groups] = ['admin', inst_admin_group, inst_user_group]
        permissions[:read_groups] = ['admin', inst_admin_group, inst_user_group]
        permissions[:edit_groups] = ['admin', inst_admin_group]
      when 'restricted'
        permissions[:discover_groups] = ['admin', inst_admin_group, inst_user_group]
        permissions[:read_groups] = ['admin', inst_admin_group]
        permissions[:edit_groups] = ['admin', inst_admin_group]
    end
    self.permissions = permissions
    permissions
  end

  def check_permissions
    self.permissions
  end

  private
  def identifier_is_unique
    return if self.identifier.nil?
    count = 0;
    objects = IntellectualObject.where(identifier: self.identifier)
    unless objects.count == 0
      count +=1 if objects.count == 1 && objects.first.id != self.id
      count = objects.count if objects.count > 1
    end
    if(count > 0)
      errors.add(:identifier, 'has already been taken')
    end
  end

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

  def unique_file_identifier(identifier)
    ident_check = true
    ident_check = false if identifier.nil?
    count = 0;
    files = GenericFile.where(identifier: self.identifier)
    count +=1 if files.count == 1 && files.first.id != self.id
    count = files.count if files.count > 1
    if(count > 0)
      ident_check = false
    end
    ident_check
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
