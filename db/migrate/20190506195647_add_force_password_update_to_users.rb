class AddForcePasswordUpdateToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :force_password_update, :boolean, default: false
  end

  def down
    add_column :users, :force_password_update
  end
end
