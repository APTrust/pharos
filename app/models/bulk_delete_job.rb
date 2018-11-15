class BulkDeleteJob < ActiveRecord::Base
  self.primary_key = 'id'
  #belongs_to :institution
  has_and_belongs_to_many :intellectual_objects
  has_and_belongs_to_many :generic_files
  has_and_belongs_to_many :emails

  validates :requested_by, :institution_id, presence: true

  ### Scopes
  scope :with_requested_by, ->(param) { where(requested_by: param) unless param.blank? }
  scope :with_institutional_approver, ->(param) { where(institutional_approver: param) unless param.blank? }
  scope :with_aptrust_approver, ->(param) { where(aptrust_approver: param) unless param.blank? }
  scope :created_before, ->(param) { where('bulk_delete_jobs.created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('bulk_delete_jobs.created_at > ?', param) unless param.blank? }
  scope :updated_before, ->(param) { where('bulk_delete_jobs.updated_at < ?', param) unless param.blank? }
  scope :updated_after, ->(param) { where('bulk_delete_jobs.updated_at > ?', param) unless param.blank? }
  scope :institutional_approval_before, ->(param) { where('bulk_delete_jobs.institutional_approval_at < ?', param) unless param.blank? }
  scope :institutional_approval_after, ->(param) { where('bulk_delete_jobs.institutional_approval_at > ?', param) unless param.blank? }
  scope :aptrust_approval_before, ->(param) { where('bulk_delete_jobs.aptrust_approval_at < ?', param) unless param.blank? }
  scope :aptrust_approval_after, ->(param) { where('bulk_delete_jobs.aptrust_approval_at > ?', param) unless param.blank? }
  scope :with_institution_identifier, ->(param) {
    joins(:institution)
        .where('institutions.identifier = ?', param) unless param.blank?
  }
  scope :with_institution, ->(param) { where(institution_id: param) unless param.blank? }
  scope :with_intellectual_object, ->(param) {
    joins(:intellectual_object)
        .where('intellectual_objects.identifier = ?', param) unless param.blank?
  }
  scope :with_generic_file, ->(param) {
    joins(:generic_file)
        .where('generic_files.identifier = ?', param) unless param.blank?
  }
  scope :discoverable, ->(current_user) {
    where(institution_id: current_user.institution.id) unless current_user.admin?
  }
  scope :readable, ->(current_user) {
    where(institution_id: current_user.institution.id) unless current_user.admin?
  }

  def self.create_job(institution, user, objects=[], files=[])
    job = BulkDeleteJob.create(requested_by: user.email)
    job.institution_id = institution.id
    if objects
      objects.each do |obj|
        job.intellectual_objects.push(obj)
      end
    end
    if files
      files.each do |file|
        job.generic_files.push(file)
      end
    end
    job.save!
    job
  end

end
