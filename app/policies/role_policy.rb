class RolePolicy < ApplicationPolicy

  def add_user?
    if user.admin?
      true
    elsif user.institutional_admin?
      (record.name == 'institutional_admin') || (record.name == 'institutional_user')
    else
      false
    end
  end

end