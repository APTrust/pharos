class WorkItemStatePolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def show?
    user.admin?
  end
end