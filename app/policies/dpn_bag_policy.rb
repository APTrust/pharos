class DpnBagPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def show?
    user.admin? || user.institution_id == record.institution.id
  end

  def index?
    user.admin? || user.institution_id == record.institution.id
  end
end