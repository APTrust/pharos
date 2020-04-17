class StorageRecordPolicy < ApplicationPolicy

  def create?
    user.admin?
  end

  def new?
    user.admin?
  end

  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def update?
    false
  end

  def edit?
    false
  end

  def destroy?
    user.admin?
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
        scope.where("0 = 1")
      end
    end
  end
end
