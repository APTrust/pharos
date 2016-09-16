class GenericFilePolicy < ApplicationPolicy

  def index?
    if user.admin?
      true
    elsif record.intellectual_object.access == 'consortia'
      user.institutional_admin? || user.institutional_user?
      # if restricted or institutional access
    else
      user.institution_id == record.intellectual_object.institution.id
    end
  end

  # for adding premis events
  def add_event?
    user.admin? ||
        (user.institutional_admin? && user.institution_id == record.intellectual_object.institution.id)
  end

  # for adding checksums
  def create_through_generic_file?
    user.admin?  ||
        (user.institutional_admin? && user.institution_id == record.institution.id)
  end

  def show?
    if user.admin?
      true
    elsif record.intellectual_object.access == 'consortia'
      user.institutional_admin? || user.institutional_user?
    elsif record.intellectual_object.access == 'institution'
      user.institution_id == record.intellectual_object.institution.id
      # if restricted access
    else
      user.institutional_admin? && user.institution_id == record.intellectual_object.institution.id
    end
  end

  def update?
    user.admin?
  end

  def edit?
    false
  end

  def destroy?
    soft_delete?
  end

  def soft_delete?
    user.admin? ||
        (user.institutional_admin? && user.institution_id == record.intellectual_object.institution.id)
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
        scope.where(:intellectual_object => { :institution_id => user.institution_id })
      end
    end
  end
end