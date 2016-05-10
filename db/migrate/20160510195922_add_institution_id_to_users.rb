class AddInstitutionIdToUsers < ActiveRecord::Migration
  def change
    rename_column :users, :institution_pid, :institution_id
  end
end
