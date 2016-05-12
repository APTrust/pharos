class AddInstitutionsToUsers < ActiveRecord::Migration
  def change
    add_reference :institutions, :user, index: true
    add_foreign_key :institutions, :users
  end
end
