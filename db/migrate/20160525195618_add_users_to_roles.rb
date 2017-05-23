class AddUsersToRoles < ActiveRecord::Migration[4.2]
  def up
    create_table :roles_users, :id => false do |t|
      t.references :role
      t.references :user
    end
    add_index :roles_users, [:role_id, :user_id]
    add_index :roles_users, [:user_id, :role_id]
  end
end
