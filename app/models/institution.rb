class Institution < ActiveRecord::Base
  has_many :users
  has_many :intellectual_objects
  has_many :generic_files, through: :intellectual_objects
  has_many :premis_events, through: :intellectual_objects
  has_many :premis_events, through: :generic_files
  has_many :snapshots

  validates :name, :identifier, :type, presence: true
  validate :name_is_unique
  validate :identifier_is_unique

  before_destroy :check_for_associations

  def to_param
    identifier
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

  def active_files
    self.generic_files.where(state: 'A')
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

  def serializable_hash(options={})
    { id: id, name: name, brief_name: brief_name, identifier: identifier, dpn_uuid: dpn_uuid }
  end

  def bytes_by_format
    stats = self.generic_files.where(state: 'A').sum(:size)
    if stats
      cross_tab = self.generic_files.group(:file_format).sum(:size)
      cross_tab['all'] = stats
      cross_tab
    else
      {'all' => 0}
    end
  end

  def average_file_size
    files = self.generic_files.where(state: 'A')
    (files.count == 0) ? avg = 0 : avg = files.sum(:size) / files.count
    avg
  end

  def average_file_size_across_repo
    files = GenericFile.where(state: 'A')
    (files.count == 0) ? avg = 0 : avg = files.sum(:size) / files.count
    avg
  end

  def statistics
    stats = self.generic_files.order(:created_at).group(:created_at).sum(:size)
    time_fixed = []
    stats.each do |key, value|
      current_point = [key.to_time.to_i*1000, value.to_i]
      time_fixed.push(current_point)
    end
    time_fixed
  end

  def group_statistics
    stats = GenericFile.all.order(:created_at).group(:created_at).sum(:size)
    time_fixed = []
    stats.each do |key, value|
      current_point = {x: key.to_time.to_i*1000, y: value.to_i}
      time_fixed.push(current_point)
    end
    time_fixed
  end

  def chart_statistics
    stats = self.generic_files.order(:created_at).group(:created_at).sum(:size)
    time_fixed = []
    stats.each do |key, value|
      current_point = {x: key.to_time.to_i*1000, y: value.to_i}
      time_fixed.push(current_point)
    end
    time_fixed
  end

  def monthly_breakdown
    monthly_hash = []
    monthly_labels = ['February 2018', 'January 2018', 'December 2017', 'November 2017',  'October 2017', 'September 2017', 'August 2017',
                      'July 2017', 'June 2017', 'May 2017', 'April 2017', 'March 2017', 'February 2017', 'January 2017', 'December 2016',
                      'November 2016', 'October 2016','September 2016', 'August 2016', 'July 2016', 'June 2016', 'May 2016', 'April 2016',
                      'March 2016', 'February 2016', 'January 2016']
    monthly_hash.push(monthly_labels)
    monthly_data = [ ]
    monthly_data.push(self.generic_files.created_before('2018-03-1 00:00:00 -0000').created_after('2018-02-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2018-02-1 00:00:00 -0000').created_after('2018-01-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2018-01-1 00:00:00 -0000').created_after('2017-12-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-12-1 00:00:00 -0000').created_after('2017-11-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-11-1 00:00:00 -0000').created_after('2017-10-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-10-1 00:00:00 -0000').created_after('2017-09-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-09-1 00:00:00 -0000').created_after('2017-08-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-08-1 00:00:00 -0000').created_after('2017-07-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-07-1 00:00:00 -0000').created_after('2017-06-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-06-1 00:00:00 -0000').created_after('2017-05-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-05-1 00:00:00 -0000').created_after('2017-04-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-04-1 00:00:00 -0000').created_after('2017-03-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-03-1 00:00:00 -0000').created_after('2017-02-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-02-1 00:00:00 -0000').created_after('2017-01-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2017-01-1 00:00:00 -0000').created_after('2016-12-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-12-1 00:00:00 -0000').created_after('2016-11-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-11-1 00:00:00 -0000').created_after('2016-10-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-10-1 00:00:00 -0000').created_after('2016-09-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-09-1 00:00:00 -0000').created_after('2016-08-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-08-1 00:00:00 -0000').created_after('2016-07-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-07-1 00:00:00 -0000').created_after('2016-06-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-06-1 00:00:00 -0000').created_after('2016-05-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-05-1 00:00:00 -0000').created_after('2016-04-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-04-1 00:00:00 -0000').created_after('2016-03-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-03-1 00:00:00 -0000').created_after('2016-02-1 00:00:00 -0000').sum(:size) )
    monthly_data.push(self.generic_files.created_before('2016-02-1 00:00:00 -0000').created_after('2016-01-1 00:00:00 -0000').sum(:size) )
    monthly_hash.push(monthly_data)
    monthly_hash
  end

  def generate_overview_apt
    report = {}
    report[:bytes_by_format] = GenericFile.bytes_by_format
    report[:intellectual_objects] = IntellectualObject.where(state: 'A').count
    report[:generic_files] = GenericFile.where(state: 'A').count
    report[:premis_events] = PremisEvent.count
    report[:work_items] = WorkItem.count
    report[:average_file_size] = self.average_file_size_across_repo
    report
  end

  def self.breakdown
    report = {}
    MemberInstitution.all.each do |inst|
      size = inst.generic_files.sum(:size)
      name = inst.name
      indiv_breakdown = {}
      indiv_breakdown[name] = size
      subscribers = SubscriptionInstitution.where(member_institution_id: inst.id)
      indiv_breakdown[:subscriber_number] = subscribers.count
      subscribers.each do |si|
        si_size = si.generic_files.sum(:size)
        si_name = si.name
        indiv_breakdown[si_name] = si_size
      end
      report[name] = indiv_breakdown
    end
    report
  end

  def self.snapshot_wrapper(institution)
    storage_rate = 0.000000000381988
    snapshot_array = []
    snapshot_array.push(Institution.snapshot(institution, storage_rate))
    subscribers = SubscriptionInstitution.where(member_institution_id: institution.id)
    subscribers.each do |si|
      snapshot_array.push(Institution.snapshot(si, storage_rate))
    end
    snapshot_array
  end

  def self.snapshot(institution, rate)
    apt_bytes = institution.active_files.sum(:size)
    snapshot = Snapshot.create(institution_id: institution.id, audit_date: Time.now, apt_bytes: apt_bytes)
    if apt_bytes < 10995116277760 #10 TB
      cost = 0
    else
      excess = apt_bytes - 10995116277760
      cost = apt_bytes * rate
    end
    unless institution.dpn_uuid.empty?
      #write a query that checks intellectual objects dpn_uuids and, if present, joins to generic files to find sizes
    end
    snapshot.save!
    snapshot
  end

  private

  def name_is_unique
    return if self.name.nil?
    errors.add(:name, 'has already been taken') if Institution.where(name: self.name).reject{|r| r == self}.any?
  end

  def identifier_is_unique
    return if self.identifier.nil?
    count = 0;
    insts = Institution.where(identifier: self.identifier)
    count +=1 if insts.count == 1 && insts.first.id != self.id
    count = insts.count if insts.count > 1
    if(count > 0)
      errors.add(:identifier, 'has already been taken')
    end
    unless self.identifier.include?('.')
      errors.add(:identifier, 'must be a valid domain name')
    end
    unless self.identifier.include?('com') || self.identifier.include?('org') || self.identifier.include?('edu')
      errors.add(:identifier, "must end in '.com', '.org', or '.edu'")
    end

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
