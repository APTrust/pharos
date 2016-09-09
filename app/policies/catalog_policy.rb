class CatalogPolicy < ApplicationPolicy

  def search?
    true
  end

  def feed?
    true
  end

end