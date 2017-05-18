class DpnWorkItemPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def show?
    user.admin?
  end

  def index?
    user.admin?
  end

  def requeue?
    user.admin?
  end
end