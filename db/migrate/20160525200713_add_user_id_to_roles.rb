class AddUserIdToRoles < ActiveRecord::Migration
  def change
    add_reference :roles, :user, index: true
    add_foreign_key :roles, :users
  end
end
