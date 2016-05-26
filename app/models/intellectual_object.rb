class IntellectualObject < ActiveRecord::Base
  #include Auditable   # premis events

  belongs_to :institution
  has_many :generic_files
  has_many :premis_events
  has_many :checksums, through: :generic_files
  accepts_nested_attributes_for :generic_files

  validates :title, presence: true
  validates :institution, presence: true
  validates :identifier, presence: true
  validates :access, presence: true
  validates_inclusion_of :access, in: %w(consortia institution restricted), message: "#{:access} is not a valid access", if: :access
  validate :identifier_is_unique

  before_save :set_bag_name
  before_save :active_files
  before_destroy :check_for_associations

  def to_param
    identifier
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
    stats = self.sum(:size)
    if stats
      cross_tab = self.group(:file_format).sum(:size)
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
    dpn = Fluctus::Application::FLUCTUS_ACTIONS['dpn']
    record = Fluctus::Application::FLUCTUS_STAGES['record']
    success = Fluctus::Application::FLUCTUS_STATUSES['success']
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
    count = 0
    self.generic_files.each { |gf| count = count+1 unless gf.state == 'D' }
    count
  end

  def gf_size
    size = 0
    self.generic_files.each { |gf| size = size+gf.size unless gf.state == 'D' }
    size
  end

  def active_files
    files = []
    self.generic_files.each { |gf| files.push(gf) unless gf.state == 'D'}
    files
  end

  # This is for serializing JSON in the API.
  def serializable_hash(options={})
    data = {
        id: id,
        title: title,
        description: description,
        access: access,
        bag_name: bag_name,
        identifier: identifier,
        state: state,
    }
    data.merge!(alt_identifier: serialize_alt_identifiers)
    if options.has_key?(:include)
      options[:include].each do |opt|
        if opt.is_a?(Hash) && opt.has_key?(:active_files)
          data.merge!(active_files: serialize_active_files(opt[:active_files]))
        end
      end
      data.merge!(premisEvents: serialize_events) if options[:include].include?(:premisEvents)
      if options[:include].include?(:etag)
        item = WorkItem.last_ingested_version(self.identifier)
        data.merge!(etag: item.etag) unless item.nil?
      end
    end
    data
  end

  def serialize_active_files(options={})
    self.active_files.map do |file|
      file.serializable_hash(options)
    end
  end

  def serialize_events
    self.premisEvents.events.map do |event|
      event.serializable_hash
    end
  end

  def serialize_alt_identifiers
    data = []
    alt_identifier.each do |ident|
      data.push(ident)
    end
    data
  end

  def check_permissions
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
    permissions
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

  def set_bag_name
    return if self.identifier.nil?
    if self.bag_name.nil? || self.bag_name == ''
      pieces = self.identifier.split('/')
      i = 1
      while i < pieces.count do
        (i == 1) ? name = pieces[1] : name = "#{name}/#{pieces[i]}"
        i = i+1
      end
      self.bag_name = name
    end
  end

  def check_for_associations
    # Check for related GenericFiles
    unless generic_file_ids.empty?
      errors[:base] << "Cannot delete #{self.id} because Generic Files are associated with it"
    end
    errors[:base].empty?
  end

end
