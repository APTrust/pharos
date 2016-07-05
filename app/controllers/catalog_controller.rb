class CatalogController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized

  def search
    authorize current_user
    case params[:object_type]
      when 'object'
        object_search
      when 'file'
        file_search
      when 'item'
        item_search
      when '*'
        generic_search
    end
    filter_results
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

  def object_search
    @results = []
    case params[:search_field]
      when 'identifier'
        @results = IntellectualObject.where(identifier: params[:q])
      when 'alt_identifier'
        @results = IntellectualObject.where(alternate_identifier: params[:q])
      when 'bag_name'
        @results = IntellectualObject.where(bag_name: params[:q])
      when 'title'
        @results = IntellectualObject.where(title: params[:q])
      when '*'
        @results << IntellectualObject.where(identifier: params[:q])
        @results << IntellectualObject.where(alternate_identifier: params[:q])
        @results << IntellectualObject.where(bag_name: params[:q])
        @results << IntellectualObject.where(title: params[:q])
    end
  end

  def file_search
    @results = []
    case params[:search_field]
      when 'identifier'
        @results = GenericFile.where(identifier: params[:q])
      when 'uri'
        @results = GenericFile.where(uri: params[:q])
      when '*'
        @results << GenericFile.where(identifier: params[:q])
        @results << GenericFile.where(uri: params[:q])
    end
  end

  def item_search
    @results = []
    case params[:search_field]
      when 'name'
        @results = WorkItem.where(name: params[:q])
      when 'etag'
        @results = WorkItem.where(etag: params[:q])
      when 'object_identifier'
        @results = WorkItem.where(intellectual_object_identifier: params[:q])
      when 'file_identifier'
        @results = WorkItem.where(generic_file_identifier: params[:q])
      when '*'
        @results << WorkItem.where(name: params[:q])
        @results << WorkItem.where(etag: params[:q])
        @results << WorkItem.where(intellectual_object_identifier: params[:q])
        @results << WorkItem.where(generic_file_identifier: params[:q])
    end
  end

  def generic_search
    @results = []
    case params[:search_field]
      when 'identifier'
        @results << IntellectualObject.where(identifier: params[:q])
        @results << GenericFile.where(identifier: params[:q])
      when 'alt_identifier'
        @results << IntellectualObject.where(alternate_identifier: params[:q])
        @results << WorkItem.where(intellectual_object_identifier: params[:q])
        @results << WorkItem.where(generic_file_identifier: params[:q])
      when 'bag_name'
        @results << IntellectualObject.where(bag_name: params[:q])
        @results << WorkItem.where(name: params[:q])
      when 'title'
        @results = IntellectualObject.where(title: params[:q])
      when 'uri'
        @results = GenericFile.where(uri: params[:q])
      when 'name'
        @results << IntellectualObject.where(bag_name: params[:q])
        @results << WorkItem.where(name: params[:q])
      when 'etag'
        @results = WorkItem.where(etag: params[:q])
      when 'object_identifier'
        @results = WorkItem.where(intellectual_object_identifier: params[:q])
      when 'file_identifier'
        @results = WorkItem.where(generic_file_identifier: params[:q])
      when '*'
        @results << IntellectualObject.where(identifier: params[:q])
        @results << IntellectualObject.where(alternate_identifier: params[:q])
        @results << IntellectualObject.where(bag_name: params[:q])
        @results << IntellectualObject.where(title: params[:q])
        @results << GenericFile.where(identifier: params[:q])
        @results << GenericFile.where(uri: params[:q])
        @results << WorkItem.where(name: params[:q])
        @results << WorkItem.where(etag: params[:q])
        @results << WorkItem.where(intellectual_object_identifier: params[:q])
        @results << WorkItem.where(generic_file_identifier: params[:q])
    end
  end

  def filter_results
    filter_by_status if params[:status].present?
    filter_by_stage if params[:stage].present?
    filter_by_action if params[:object_action].present?
    filter_by_institution if params[:institution].present?
    filter_by_access if params[:access].present?
    filter_by_format if params[:format].present?
    filter_by_association if params[:association].present?
    filter_by_type if params[:object_type].present?
  end

  def filter_by_status
    @results = @results.where(status: params[:status])
    @selected[:status] = params[:status]
  end

  def filter_by_stage
    @results = @results.where(stage: params[:stage])
    @selected[:stage] = params[:stage]
  end

  def filter_by_action
    @results = @results.where(action: params[:object_action])
    @selected[:object_action] = params[:object_action]
  end

  def filter_by_institution
    @results = @results.where(institution: params[:institution])
    @selected[:institution] = params[:institution]
  end

  def filter_by_access
    @results = @results.where(access: params[:access])
    @selected[:access] = params[:access]
  end

  def filter_by_format
    #TODO: make sure this is applicable to objects as well as files
    @results = @results.where(format: params[:format])
    @selected[:format] = params[:format]
  end

  def filter_by_association
    filtered_results = []
    filtered_results << @results.where(intellectual_object_id: params[:association])
    filtered_results << @results.where(generic_file_id: params[:association])
    @results = filtered_results
    @selected[:association] = params[:association]
  end

  def filter_by_type
    @results = @results.where(type: params[:type])
    @selected[:type] = params[:type]
  end

end