class CatalogController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized

  def search
    authorize current_user

  end

  protected

  def permission(current_object)
    permissions = current_object.check_permissions
    admin_group = "Admin_At_#{current_user.institution_id}"
    user_group = "User_At_#{current_user.institution_id}"
    if current_user.admin?
      true
    elsif current_user.institutional_admin?
      (permissions[:discover_group].include?('institutional_admin') || permissions[:discover_group].include?(admin_group)) ? true : false
    elsif current_user.institutional_user?
      (permissions[:discover_group].include?('institutional_user') || permissions[:discover_group].include?(user_group)) ? true : false
    end
  end

end