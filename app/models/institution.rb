class Institution < ActiveRecord::Base
  require 'csv'
  require 'zlib'
  require 'rubygems'
  require 'zip'

  self.primary_key = 'id'
  has_many :users
  has_many :intellectual_objects
  has_many :generic_files, through: :intellectual_objects
  has_many :premis_events, through: :intellectual_objects
  has_many :premis_events, through: :generic_files
  has_many :snapshots
  has_many :dpn_bags
  has_many :bulk_delete_jobs
  has_one :confirmation_token

  before_validation :sanitize_update_params, on: :update

  validates :name, :identifier, :type, presence: true
  validate :name_is_unique
  validate :domain_is_allowed
  validates_uniqueness_of :identifier

  attr_readonly :identifier

  before_destroy :check_for_associations

  def to_param
    identifier
  end

  def is_in_dpn
    status = false
    if self.dpn_uuid != '' || self.dpn_uuid != nil
      status = true
    end
    status
  end

  def self.find_by_identifier(identifier)
    Institution.where(identifier: identifier).first
  end

  # Return the users that belong to this institution.  Sorted by name for display purposes primarily.
  def users
    User.where(institution_id: self.id).to_a.sort_by(&:name)
  end

  def admin_users
    admin_users = []
    users = User.where(institution_id: self.id)
    users.each { |user| admin_users.push(user) if user.institutional_admin? }
    admin_users
  end

  def apt_users
    apt_users = []
    apt = Institution.where(identifier: "aptrust.org").first
    users = User.where(institution_id: apt.id)
    users.each { |user| apt_users.push(user) if user.admin? }
    apt_users
  end

  def active_files
    GenericFile.where(institution_id: self.id, state: 'A')
  end

  def new_deletion_items
    latest_email = Email.where(institution_id: self.id, email_type: 'deletion_notifications').order(id: :asc).limit(1).first
    if latest_email.nil?
      time = Time.now - 1.month
      deletion_items = WorkItem.with_institution(self.id)
                           .created_after(time)
                           .with_action(Pharos::Application::PHAROS_ACTIONS['delete'])
                           .with_stage(Pharos::Application::PHAROS_STAGES['resolve'])
                           .with_status(Pharos::Application::PHAROS_STATUSES['success'])
    else
      deletion_items = WorkItem.with_institution(self.id)
                           .created_after(latest_email.created_at)
                           .with_action(Pharos::Application::PHAROS_ACTIONS['delete'])
                           .with_stage(Pharos::Application::PHAROS_STAGES['resolve'])
                           .with_status(Pharos::Application::PHAROS_STATUSES['success'])
    end
    deletion_items
  end

  def generate_deletion_csv(deletion_items)
    directory = "./tmp/deletions_#{Rails.env}"
    inst_name = deletion_items.first.institution.name.split(' ').join('_')
    Dir.mkdir("#{directory}") unless Dir.exist?("#{directory}")
    Dir.mkdir("#{directory}/#{Time.now.month}-#{Time.now.day}-#{Time.now.year}") unless Dir.exist?("#{directory}/#{Time.now.month}-#{Time.now.day}-#{Time.now.year}")
    Dir.mkdir("#{directory}/#{Time.now.month}-#{Time.now.day}-#{Time.now.year}/#{inst_name}") unless Dir.exist?("#{directory}/#{Time.now.month}-#{Time.now.day}-#{Time.now.year}/#{inst_name}")
    attributes = ['Generic File Identifier', 'Date Deleted', 'Requested By', 'Approved By', 'APTrust Approver']
    CSV.open("#{directory}/#{Time.now.month}-#{Time.now.day}-#{Time.now.year}/#{inst_name}/#{inst_name}.csv", 'w', write_headers: true, headers: attributes) do |csv|
      deletion_items.each do |item|
        unless item.generic_file_identifier.nil?
          item.inst_approver.nil? ? inst_app = 'NA' : inst_app = item.inst_approver
          item.aptrust_approver.nil? ? apt_app = 'NA' : apt_app = item.aptrust_approver
          row = [item.generic_file_identifier, item.date.to_s, item.user, inst_app, apt_app]
          csv << row
        end
      end
    end
  end

  def generate_deletion_zipped_csv(deletion_items)
    inst_name = deletion_items.first.institution.name.split(' ').join('_')
    directory = "./tmp/deletions_#{Rails.env}/#{Time.now.month}-#{Time.now.day}-#{Time.now.year}/#{inst_name}"
    csv = generate_deletion_csv(deletion_items)
    output_file = "#{directory}/#{inst_name}.zip"
    zf = ZipFileGenerator.new(directory, output_file)
    zf.write()
  end

  def self.remove_directory(env)
    if env == 'test'
      directory = "./tmp/deletions_#{env}/#{Time.now.month}-#{Time.now.day}-#{Time.now.year}"
    else
      directory = "./tmp/deletions_#{env}/#{Time.now.month - 3.months}-#{Time.now.day}-#{Time.now.year}"
    end
    FileUtils.rm_rf(directory)
  end

  def generate_confirmation_csv(bulk_job)
    attributes = ['Identifier']
    CSV.generate(headers: true) do |csv|
      csv << attributes
      bulk_job.intellectual_objects.each do |object|
        row = [object.identifier]
        csv << row
      end
      bulk_job.generic_files.each do |file|
        row = [file.identifier]
        csv << row
      end
    end
  end

  def deletion_admin_user(requesting_user)
    confirming_users = []
    admin_users = self.admin_users
    if admin_users.count == 1
      confirming_users.push(admin_users.first)
    else
      admin_users.each { |user| confirming_users.push(user) if user.name != requesting_user.name }
    end
    confirming_users
  end

  def bulk_deletion_users(requesting_user)
    confirming_users = []
    apt_users = self.apt_users
    if apt_users.count == 1
      confirming_users.push(apt_users.first)
    else
      apt_users.each { |user| confirming_users.push(user) if user.name != requesting_user.name }
    end
    confirming_users
  end

  def serializable_hash(options={})
    { id: id, name: name, identifier: identifier, dpn_uuid: dpn_uuid }
  end

  def bytes_by_format
    stats = self.total_file_size
    if stats
      cross_tab = self.active_files.group(:file_format).sum(:size)
      cross_tab['all'] = stats
      cross_tab
    else
      {'all' => 0}
    end
  end

  def deactivate
    update_attribute(:deactivated_at, Time.current)
    self.users.each do |user|
      user.soft_delete
    end
  end

  def reactivate
    update_attribute(:deactivated_at, nil)
    self.users.each do |user|
      user.reactivate
    end
  end

  def deactivated?
    return !self.deactivated_at.nil?
  end

  def average_file_size
    query = "SELECT AVG(size) FROM (SELECT size FROM generic_files WHERE institution_id = #{self.id} AND state = 'A') AS institution_file_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    result[0]['avg'].to_i
  end

  def self.average_file_size_across_repo
    query = "SELECT AVG(size) FROM (SELECT size FROM generic_files WHERE state = 'A') AS aptrust_file_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    result[0]['avg'].to_i
  end

  def total_file_size
    query = "SELECT SUM(size) FROM (SELECT size FROM generic_files WHERE institution_id = #{self.id} AND state = 'A') AS institution_total_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    result[0]['sum'].to_i
  end

  def core_service_size
    query = "SELECT SUM(size) FROM (SELECT size FROM generic_files WHERE institution_id = #{self.id} AND state = 'A' AND storage_option = 'Standard') AS institution_core_service_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    result[0]['sum'].to_i
  end

  def glacier_only_size
    query = "SELECT SUM(size) FROM (SELECT size FROM generic_files WHERE institution_id = #{self.id} AND state = 'A' AND storage_option = 'Glacier-OH') AS institution_glacier_oh_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    glacier_oh = result[0]['sum'].to_i
    query = "SELECT SUM(size) FROM (SELECT size FROM generic_files WHERE institution_id = #{self.id} AND state = 'A' AND storage_option = 'Glacier-VA') AS institution_glacier_va_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    glacier_va = result[0]['sum'].to_i
    query = "SELECT SUM(size) FROM (SELECT size FROM generic_files WHERE institution_id = #{self.id} AND state = 'A' AND storage_option = 'Glacier-OR') AS institution_glacier_or_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    glacier_or = result[0]['sum'].to_i
    glacier_oh + glacier_va + glacier_or
  end

  def self.total_file_size_across_repo
    query = "SELECT SUM(size) FROM (SELECT size FROM generic_files WHERE state = 'A') AS aptrust_total_size"
    result = ActiveRecord::Base.connection.exec_query(query)
    result[0]['sum'].to_i
  end

  def object_count
    if self.name == 'APTrust'
      query = "SELECT COUNT(*) FROM (SELECT identifier FROM intellectual_objects WHERE state = 'A') AS aptrust_objects"
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['count']
    else
      query = "SELECT COUNT(*) FROM (SELECT identifier FROM intellectual_objects WHERE institution_id = #{self.id} AND state = 'A') AS institution_objects"
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['count']
    end
    count
  end

  def file_count
    if self.name == 'APTrust'
      query = "SELECT COUNT(*) FROM (SELECT identifier FROM generic_files WHERE state = 'A') AS aptrust_files"
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['count']
    else
      query = "SELECT COUNT(*) FROM (SELECT identifier FROM generic_files WHERE institution_id = #{self.id} AND state = 'A') AS institution_files"
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['count']
    end
    count
  end

  def event_count
    if self.name == 'APTrust'
      query = "select reltuples from pg_class where relname = 'premis_events'"
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['reltuples']
    else
      query = "SELECT COUNT(*) FROM (SELECT identifier FROM premis_events WHERE institution_id = #{self.id}) AS institution_events"
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['count']
    end
    count
  end

  def item_count
    if self.name == 'APTrust'
      query = 'SELECT COUNT(*) FROM (SELECT id FROM work_items) AS institution_items'
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['count']
    else
      query = "SELECT COUNT(*) FROM (SELECT id FROM work_items WHERE institution_id = #{self.id}) AS institution_items"
      result = ActiveRecord::Base.connection.exec_query(query)
      count = result[0]['count']
    end
    count
  end

  def generate_timeline_report
    monthly_hash = []
    monthly_labels = []
    monthly_data = []
    earliest_date = '2014-12-1T00:00:00+00:00'
    iterative_date = (DateTime.current+1.month).beginning_of_month
    while iterative_date.to_s > earliest_date do
      before_date = iterative_date - 1.month
      monthly_labels.push(convert_datetime_to_label(before_date))
      if self.name == 'APTrust'
        monthly_data.push(GenericFile.created_before(iterative_date.to_s).created_after(before_date.to_s).sum(:size))
      else
        monthly_data.push(self.generic_files.created_before(iterative_date.to_s).created_after(before_date.to_s).sum(:size))
      end
      iterative_date = before_date
    end
    monthly_hash.push(monthly_labels)
    monthly_hash.push(monthly_data)
    monthly_hash
  end

  def convert_datetime_to_label(date)
    date.strftime('%B %Y')
  end

  def self.generate_overview_apt
    report = {}
    report[:bytes_by_format] = GenericFile.bytes_by_format
    report[:intellectual_objects] = IntellectualObject.where(state: 'A').count
    report[:generic_files] = GenericFile.where(state: 'A').count
    report[:premis_events] = PremisEvent.count
    report[:work_items] = WorkItem.count
    report[:average_file_size] = Institution.average_file_size_across_repo
    report
  end

  def self.breakdown
    report = {}
    MemberInstitution.all.order('name').each do |inst|
      if inst.name == 'APTrust'
        name = 'APTrust (Repository Total)'
        size = Institution.total_file_size_across_repo
      else
        name = inst.name
        size = inst.total_file_size
      end
      indiv_breakdown = {}
      indiv_breakdown[:size] = size
      subscribers = SubscriptionInstitution.where(member_institution_id: inst.id)
      indiv_breakdown[:subscriber_number] = subscribers.count
      subscribers.each do |si|
        si_size = si.total_file_size
        si_name = si.name
        indiv_breakdown[si_name] = si_size
        size += si_size
      end
      indiv_breakdown[:total_size] = size
      report[name] = indiv_breakdown
    end
    report
  end

  private

  def name_is_unique
    return if self.name.nil?
    errors.add(:name, 'has already been taken') if Institution.where(name: self.name).reject{|r| r == self}.any?
  end

  def domain_is_allowed
    return if self.identifier.nil?
    errors.add(:identifier, 'must be a valid domain name') unless self.identifier.include?('.')
    errors.add(:identifier, "must end in '.com', '.org', '.edu', or .museum") unless Pharos::Application::VALID_DOMAINS.include?(self.identifier.split('.').last)
  end

  def sanitize_update_params
    restore_attributes(['identifier', :identifier])
  end

  def check_for_associations
    if User.where(institution_id: self.id).count != 0
      errors[:base] << "Cannot delete #{self.name} because some Users are associated with this Institution"
    end
    if self.intellectual_objects.count != 0
      errors[:base] << "Cannot delete #{self.name} because Intellectual Objects are associated with this Institution"
    end
    if self.generic_files.count != 0
      errors[:base] << "Cannot delete #{self.name} because Generic Files are associated with this Institution"
    end
    if self.premis_events.count != 0
      errors[:base] << "Cannot delete #{self.name} because Premis Events are associated with this Institution"
    end
    if WorkItem.where(institution_id: self.id).count != 0
      errors[:base] << "Cannot delete #{self.name} because Work Items are associated with this Institution"
    end
    if errors[:base].empty?
      true
    else
      throw(:abort)
    end
  end

end
