class UserPolicy < ApplicationPolicy

  def create?
    user.admin? || user.institutional_admin?
  end

  def new?
    create?
  end

  def index?
    user.admin? ||
        (user.institutional_admin? && (user.institution_pid == record.institution_pid))
  end

  def show?
    user == record ||  user.admin? ||
        (user.institutional_admin? && (user.institution_pid == record.institution_pid))
  end

  def edit?
    update?
  end

  def update?
    user == record || user.admin? ||
        (user.institutional_admin? && (user.institution_pid == record.institution_pid))
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

  # institutional_admin cannot delelte institutional user
  def destroy?
    return false if user == record
    user.admin? ||
        (user.institutional_admin? && (user.institution_pid == record.institution_pid))
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
        scope.where(institution_pid: user.institution_pid)
      end
    end
  end
end
