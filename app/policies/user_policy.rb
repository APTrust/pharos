class UserPolicy < ApplicationPolicy

  def create?
    user.admin? || user.institutional_admin?
  end

  def new?
    create?
  end

  def index?
    user.admin? ||
        (user.institutional_admin? && (user.institution_id == record.institution_id))
  end

  def search?
    true
  end

  def feed?
    true
  end

  def nil_index?
    true
  end

  def set_restoration_status?
    user.admin?
  end

  def state_show?
    user.admin?
  end

  def checksum_index?
    user.admin?
  end

  def dpn_show?
    user.admin?
  end

  def dpn_index?
    user.admin?
  end

  def show?
    user == record ||  user.admin? ||
        (user.institutional_admin? && (user.institution_id == record.institution_id))
  end

  def edit?
    update?
  end

  def update?
    return false if (user.institutional_admin? && record.admin?)
    user == record || user.admin? ||
        (user.institutional_admin? && (user.institution_id == record.institution_id))
  end

  # institutional_admin cannot generate key for institutional user
  def generate_api_key?
    user.admin? || user == record
  end

  def update_password?
    user.admin? || user == record
  end

  def edit_password?
    update_password?
  end

  def admin_password_reset?
    user.admin?
  end

  def work_item_batch_update?
    user.admin?
  end

  def not_checked_since?
    user.admin?
  end

  def intellectual_object_create?
    user.admin?
  end

  def destroy?
    return false if user == record
    return false if (user.institutional_admin? && record.admin?)
    user.admin? ||
        (user.institutional_admin? && (user.institution_id == record.institution_id))
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      else
        scope.where(institution_id: user.institution_id)
      end
    end
  end
end
