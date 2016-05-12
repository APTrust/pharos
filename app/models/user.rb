require 'bcrypt'
require 'valid_email'

class User < ActiveRecord::Base
  belongs_to :institution, foreign_key: :institution_id
  has_many :roles

  # Include default devise modules. Others available are:
  # :database_authenticatable,
  # :recoverable, :rememberable, :trackable, :validatable,
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable,
         :timeoutable, :validatable

  validates :email, :phone_number, :role_ids, presence: true
  validates :email, uniqueness: true
  validates :institution_id, presence: true
  validate :institution_id_points_at_institution
  validates :name, presence: true, if: ->{ name.present? } #TODO: find name validator that actually works
  validates :email, email: true
  phony_normalize :phone_number, :default_country_code => 'US'
  validates :phone_number, :phony_plausible => true

  # This method assigns permission groups
  # Don't think these are necessary anymore, we use Pundit/Roles
  def groups
    super + institution_groups
  end

  def institution_groups
    if institutional_admin?
      ["Admin_At_#{institution_group_suffix}"]
    elsif institutional_user?
      ["User_At_#{institution_group_suffix}"]
    else
      []
    end
  end

  def institution_identifier
    institution = Institution.find(self.institution_id)
    institution.identifier
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

  def role_id
    if(admin?)
      Role.where(name: 'admin').first_or_create.id
    elsif(institutional_admin?)
      Role.where(name: 'institutional_admin').first_or_create.id
    elsif(institutional_user?)
      Role.where(name: 'institutional_user').first_or_create.id
    end
  end

  def main_group
    if(admin?)
      'Admin'
    elsif(institutional_admin?)
      'Institutional Admin'
    elsif(institutional_user?)
      'Institutional User'
    end
  end

  def institution_group_suffix
    institution_id
  end

  def guest?
    false
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

  class NilInstitution
    def name
      'Deleted Institution'
    end

    def to_param
      'deleted'
    end

    def brief_name
      'Deleted Institution'
    end

    def users
      []
    end

    def intellectual_objects
      []
    end

    def bytes_by_format
      {}
    end
  end

  private

  def institution_id_points_at_institution
    errors.add(:institution_id, 'is not a valid institution') unless Institution.exists?(institution_id)
  end

end
