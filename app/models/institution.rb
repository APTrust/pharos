class Institution < ActiveRecord::Base

  has_many :users
  has_many :intellectual_objects
  has_many :generic_files, through: :intellectual_objects
  has_many :premis_events, through: :intellectual_objects
  has_many :premis_events, through: :generic_files

  validates :name, :identifier, presence: true
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

  def serializable_hash(options={})
    { id: id, name: name, brief_name: brief_name, identifier: identifier, dpn_uuid: dpn_uuid }
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

  def statistics
    #sample = UsageSample.where(institution_id: id).map {|sample| sample.to_flot }
    stats = self.generic_files.group(:created_at).sum(:size)
    time_fixed = []
    stats.each do |key, value|
      current_point = [key.to_time.to_i*1000, value]
      time_fixed.push(current_point)
    end
    time_fixed
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

    errors[:base].empty?
  end

end
