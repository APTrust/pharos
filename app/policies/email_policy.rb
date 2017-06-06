class EmailPolicy < ApplicationPolicy

  def index?
    current_user.admin?
  end

  def show?
    current_user.admin?
  end

end