class Institution < ActiveRecord::Base
  has_many :users
  has_many :intellectual_objects
  has_many :generic_files, through: :intellectual_objects
  has_many :premis_events, through: :intellectual_objects
  has_many :premis_events, through: :generic_files
  has_many :snapshots
  has_many :dpn_bags

  validates :name, :identifier, :type, presence: true
  validate :name_is_unique
  validate :identifier_is_unique

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

  def active_files
    GenericFile.where(institution_id: self.id, state: 'A')
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
    stats = self.active_files.sum(:size)
    if stats
      cross_tab = self.active_files.group(:file_format).sum(:size)
      cross_tab['all'] = stats
      cross_tab
    else
      {'all' => 0}
    end
  end

  def average_file_size
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      query = "SELECT AVG(size) FROM (SELECT size FROM 'generic_files' WHERE state = 'A' AND institution_id = #{self.id})"
      result = ActiveRecord::Base.connection.exec_query(query)
      result[0]['AVG(size)']
    else
      GenericFile.with_institution(self.id).with_state('A').average(:size)
    end
  end

  def self.average_file_size_across_repo
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      query = "SELECT AVG(size) FROM (SELECT size FROM 'generic_files' WHERE state = 'A')"
      result = ActiveRecord::Base.connection.exec_query(query)
      result[0]['AVG(size)']
    else
      GenericFile.with_state('A').average(:size)
    end
  end

  def total_file_size
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      query = "SELECT SUM(size) FROM (SELECT size FROM 'generic_files' WHERE state = 'A' AND institution_id = #{self.id})"
      result = ActiveRecord::Base.connection.exec_query(query)
      result[0]['SUM(size)']
    else
      GenericFile.with_institution(self.id).with_state('A').sum(:size)
    end
  end

  def self.total_file_size_across_repo
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      query = "SELECT SUM(size) FROM (SELECT size FROM 'generic_files' WHERE state = 'A')"
      result = ActiveRecord::Base.connection.exec_query(query)
      result[0]['SUM(size)']
    else
      GenericFile.with_state('A').sum(:size)
    end
  end

  def object_count
    if self.name == 'APTrust'
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "SELECT COUNT(*) FROM (SELECT identifier FROM 'intellectual_objects' WHERE state = 'A')"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0]['COUNT(*)']
      else
        count = IntellectualObject.with_state('A').count
      end
    else
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "SELECT COUNT(*) FROM (SELECT identifier FROM 'intellectual_objects' WHERE institution_id = #{self.id} AND state = 'A')"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0]['COUNT(*)']
      else
        count = IntellectualObject.with_institution(self.id).with_state('A').size
      end
    end
    count
  end

  def file_count
    if self.name == 'APTrust'
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "SELECT COUNT(*) FROM (SELECT identifier FROM 'generic_files' WHERE state = 'A')"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0]['COUNT(*)']
      else
        count = GenericFile.with_state('A').count
      end
    else
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "SELECT COUNT(*) FROM (SELECT identifier FROM 'generic_files' WHERE institution_id = #{self.id} AND state = 'A')"
        #query = "SELECT COUNT(*) FROM (SELECT 'generic_files'.'identifier' FROM 'generic_files' INNER JOIN 'intellectual_objects' ON 'intellectual_objects'.'id' = 'generic_files'.'intellectual_object_id' WHERE (intellectual_objects.institution_id = #{self.id}) AND 'generic_files'.'state' = 'A')"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0]['COUNT(*)']
      else
        count = GenericFile.with_institution(self.id).with_state('A').size
      end
    end
    count
  end

  def event_count
    if self.name == 'APTrust'
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "select reltuples from pg_class where relname = 'premis_events'"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0][0]
      else
        count = PremisEvent.count
      end
    else
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "SELECT COUNT(*) FROM (SELECT identifier FROM 'premis_events' WHERE institution_id = #{self.id})"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0]['COUNT(*)']
      else
        count = PremisEvent.with_institution(self.id).size
      end
    end
    count
  end

  def item_count
    if self.name == 'APTrust'
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "select reltuples from pg_class where relname = 'work_items'"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0][0]
      else
        count = WorkItem.count
      end
    else
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        query = "SELECT COUNT(*) FROM (SELECT id FROM 'work_items' WHERE institution_id = #{self.id})"
        result = ActiveRecord::Base.connection.exec_query(query)
        count = result.rows[0]['COUNT(*)']
      else
        count = WorkItem.with_institution(self.id).size
      end
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
      size = inst.active_files.sum(:size)
      name = inst.name
      indiv_breakdown = {}
      indiv_breakdown[:size] = size
      subscribers = SubscriptionInstitution.where(member_institution_id: inst.id)
      indiv_breakdown[:subscriber_number] = subscribers.count
      subscribers.each do |si|
        si_size = si.active_files.sum(:size)
        si_name = si.name
        indiv_breakdown[si_name] = si_size
      end
      report[name] = indiv_breakdown
    end
    report
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
