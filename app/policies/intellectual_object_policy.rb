class IntellectualObjectPolicy < ApplicationPolicy

  def index?
    if user.admin?
      true
    elsif record.access == 'consortia'
      user.institutional_admin? || user.institutional_user?
      # if restricted or institutional access
    else
      user.institution_id == record.institution.id
    end
  end

  def create?
    user.admin?
  end

  def file_summary?
    if user.admin?
      true
    elsif record.intellectual_object.access == 'consortia'
      user.institutional_admin? || user.institutional_user?
      # if restricted or institutional access
    else
      user.institution_id == record.intellectual_object.institution.id
    end
  end

  # for adding premis events - restricted to admin only so other users can't create events willy nilly
  # adding events still allowed through the soft_delete function, but only for deletion events.
  def add_event?
    user.admin?
  end

  def show?
    if user.admin?
      true
    elsif record.access == 'consortia'
      user.institutional_admin? || user.institutional_user?
    elsif record.access == 'institution'
      user.institution_id == record.institution.id
      # if restricted access
    else
      user.institutional_admin? && user.institution_id == record.institution.id
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

  # creates deletion events as part of the process of deletion
  def soft_delete?
    user.admin? ||
        (user.institutional_admin? && user.institution_id == record.institution.id)
  end

  def restore?
    user.admin? || (user.institutional_admin? && user.institution_id == record.institution.id)
  end

  def dpn?
    user.admin? || (user.institutional_admin? && user.institution_id == record.institution.id)
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
        scope.where(institution_id: user.institution_id)
      end
    end
  end
end
