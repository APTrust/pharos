class AddInstitutionsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_reference :institutions, :user, index: true
    add_foreign_key :institutions, :users
  end
end
