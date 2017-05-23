class AddUsersToInstitutions < ActiveRecord::Migration[4.2]
  def change
    add_reference :users, :institution, index: true
    add_foreign_key :users, :institutions
  end
end
