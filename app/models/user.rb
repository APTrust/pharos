require 'bcrypt'

class User < ActiveRecord::Base

  self.primary_key = 'id'
  belongs_to :institution, foreign_key: :institution_id
  has_and_belongs_to_many :roles

  # Include default devise modules. Others available are:
  # :database_authenticatable,
  # :recoverable, :rememberable, :trackable, :validatable,
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :recoverable, :rememberable, :trackable, :password_archivable,
         :timeoutable, :validatable, :two_factor_authenticatable,
         :two_factor_backupable, otp_backup_code_length: 10, :otp_secret_encryption_key => ENV['TWO_FACTOR_KEY']

  validates :email, presence: true, uniqueness: true
  validate :email_is_valid
  # validates :phone_number, presence: true
  validates_presence_of :phone_number, on: :enable_otp
  validates :role_ids, presence: true
  validates :institution_id, presence: true
  validate :institution_id_points_at_institution
  validates :name, presence: true
  phony_normalize :phone_number, :default_country_code => 'US'
  validates_plausible_phone :phone_number
  validate :init_grace_period, on: :create

  # We want this to always be true so that authorization happens in the user policy, preventing incorrect 404 errors.
  scope :readable, ->(current_user) { where('(1=1)') }

  # This method assigns permission groups
  # Don't think these are necessary anymore, we use Pundit/Roles
  def groups
    institution_groups + ['registered']
  end

  def institution_groups
    if institutional_admin?
      ["Admin_At_#{institution_group_suffix}", 'institutional_admin']
    elsif institutional_user?
      ["User_At_#{institution_group_suffix}", 'institutional_user']
    else
      ['admin']
    end
  end

  def institution_group_suffix
    institution_id
  end

  def to_s
    name || email
  end

  def as_json(options = nil)
    json_data = super
    json_data.delete('api_secret_key')
    json_data.delete('encrypted_api_secret_key')
    json_data
  end

  def is?(role)
    self.roles.pluck(:name).include?(role.to_s)
  end

  def admin?
    is? 'admin'
  end

  def institutional_admin?
    is? 'institutional_admin'
  end

  def institutional_user?
    is? 'institutional_user'
  end

  def sms_user?
    self.authy_status == 'sms' || self.authy_status.nil?
  end

  def need_two_factor_authentication?
    self.enabled_two_factor == true && self.confirmed_two_factor == true
  end

  def required_to_use_twofa?
    self.institution.otp_enabled || self.admin? || self.institutional_admin?
  end

  def self.stale_users
    users = User.where('created_at <= ? AND created_at >= ?',
                       DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 3).days,
                       DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i + 7).days, )
    stale_users = []
    users.each do |usr|
      items = WorkItem.where(user: usr.email)
      stale_users.push(usr) if items.count == 0
    end
    stale_users
  end

  def role_id
    if(admin?)
      Role.where(name: 'admin').first_or_create.id
    elsif(institutional_admin?)
      Role.where(name: 'institutional_admin').first_or_create.id
    elsif(institutional_user?)
      Role.where(name: 'institutional_user').first_or_create.id
    end
  end

  def guest?
    false
  end

  # instead of deleting, indicate the user requested a delete & timestamp it
  def soft_delete
    update_attribute(:deactivated_at, Time.current)
    update_attribute(:encrypted_api_secret_key, '')
  end

  def reactivate
    update_attribute(:deactivated_at, nil)
  end

  def deactivated?
    return !self.deactivated_at.nil?
  end

  # ensure user account is active
  def active_for_authentication?
    super && !deactivated_at
  end

  # provide a custom message for a deleted account
  def inactive_message
    !deactivated_at ? super : :deactivated_account
  end

  attr_reader :api_secret_key

  def api_secret_key=(key)
    @api_secret_key = key
    self.encrypted_api_secret_key = if key.blank?
                                      nil
                                    else
                                      password_digest(key)
                                    end
  end

  # Generate a new API key for this user
  def generate_api_key(length = 20)
    self.api_secret_key = SecureRandom.hex(length)
  end

  # Verifies whether an API key (from sign in) matches the user's API key.
  def valid_api_key?(input_key)
    return false if encrypted_api_secret_key.blank?
    bcrypt  = ::BCrypt::Password.new(encrypted_api_secret_key)
    key = ::BCrypt::Engine.hash_secret("#{input_key}#{User.pepper}", bcrypt.salt)
    Devise.secure_compare(key, encrypted_api_secret_key)
  end

  # Sets a custom session time (in seconds) for the current user.
  def set_session_timeout(seconds)
    @session_timeout = seconds
  end

  # Returns the session duration, in seconds, for the current user.
  # For API use sessions, we set a long timeout
  # For all other users, we use the config setting Devise.timeout_in,
  # which is set in config/initializers/devise.rb.
  # For info on the timeout_in method, see:
  # https://github.com/plataformatec/devise/wiki/How-To:-Add-timeout_in-value-dynamically
  def timeout_in
    if !@session_timeout.nil? && @session_timeout > 0
      @session_timeout
    else
      Devise.timeout_in
    end
  end

  private

  def institution_id_points_at_institution
    errors.add(:institution_id, 'is not a valid institution') unless Institution.exists?(institution_id)
  end

  def email_is_valid
    errors.add(:email, 'is invalid') if !EmailValidator.valid?(email)
  end

  def phone_number_length
    errors.add(:phone_number, 'is not the proper length') if phone_number.length < 10
  end

  def init_grace_period
    self.grace_period = DateTime.now
  end

  def self.phone_number_is_valid

  end

end
