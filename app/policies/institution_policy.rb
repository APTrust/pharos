class InstitutionPolicy < ApplicationPolicy

  def add_user?
    user.admin? ||
        (user.institutional_admin? && user.institution_pid == record.pid)
  end

  def create?
    user.admin?
  end

  # for intellectual_object
  def create_through_institution?
    user.admin? ||
        (user.institutional_admin? && user.institution_pid == record.pid)
  end

  def new?
    create?
  end

  def index?
    user.admin? ||  (user.institution_pid == record.pid)
  end

  def show?
    record.nil? || user.admin? ||  (user.institution_pid == record.pid)
  end

  def edit?
    update?
  end

  def update?
    user.admin? ||
        (user.institutional_admin? && (user.institution_pid == record.pid))
  end

  def destroy?
    false
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
        scope.where(pid: user.institution_pid)
      end
    end
  end

end