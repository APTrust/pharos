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

  def overview?
    user.admin? || (user.institution_id == record.id)
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

  def deactivate?
    user.admin?
  end

  def reactivate?
    user.admin?
  end

  def snapshot?
    user.admin?
  end

  def bulk_delete?
    user.admin?
  end

  def final_confirmation_bulk_delete?
    user.admin?
  end

  def partial_confirmation_bulk_delete?
    user.institutional_admin? && (user.institution_id == record.id)
  end

  def finished_bulk_delete?
    user.admin?
  end

  def bulk_delete_job_index?
    user.admin? || (user.institutional_admin? && (user.institution_id == record.id))
  end

  def reports?
    user.admin? || user.institution_id == record.id
  end

  def dpn_bag_index?
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
