class InstitutionPolicy < ApplicationPolicy

  def add_user?
    user.admin? ||
        (user.institutional_admin? && user.institution_id == record.id)
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def index?
    user.admin? ||  (user.institution_id == record.id)
  end

  def index_through_institution?
    user.admin? || record.id == user.institution_id
  end

  def show?
    user.admin? ||  (user.institution_id == record.id)
  end

  def edit?
    update?
  end

  def update?
    user.admin? ||
        (user.institutional_admin? && (user.institution_id == record.id))
  end

  def destroy?
    false
  end

  def reports?
    user.admin? || user.institution_id == record.id
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin? || (user.institutional_admin? && user.institution.name == 'APTrust')
        scope.all
      else
        scope.where(id: user.institution_id)
      end
    end
  end

end
