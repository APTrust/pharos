class BulkDeleteJobPolicy < ApplicationPolicy

  def show?
    user.admin? || (user.institutional_admin? && (user.institution_id == record.institution_id))
  end

end
