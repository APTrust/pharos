class SnapshotPolicy < ApplicationPolicy

  def index?
    if user.admin?
      true
    else
      user.institution_id == record.first.institution_id
    end
  end

  def show?
    if user.admin?
      true
    else
      user.institution_id == record.institution_id
    end
  end

end