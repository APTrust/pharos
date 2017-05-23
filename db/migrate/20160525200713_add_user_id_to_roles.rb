class AddUserIdToRoles < ActiveRecord::Migration[4.2]
  def change
    add_reference :roles, :user, index: true
    add_foreign_key :roles, :users
  end
end
