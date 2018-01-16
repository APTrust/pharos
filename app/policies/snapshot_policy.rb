class SnapshotPolicy < ApplicationPolicy

  def index?
    if user.admin?
      true
    else
      user.institution_id == record.institution.id
    end
  end

  def show?
    if user.admin?
      true
    else
      user.institution_id == record.institution.id
    end
  end

end