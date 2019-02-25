class RemoveBriefNameFromInstitutions < ActiveRecord::Migration[5.2]
  def change
    remove_column :institutions, :brief_name
  end
end
