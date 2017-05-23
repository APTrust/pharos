class RemoveInstitutionFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :institution_id
  end
end
