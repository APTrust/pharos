class AddUsersToInstitutions < ActiveRecord::Migration
  def change
    add_reference :users, :institution, index: true
    add_foreign_key :users, :institutions
  end
end
