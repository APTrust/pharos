class AddPasswordUpdatedToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :initial_password_updated, :boolean, default: false
  end

  def down
    remove_column :users, :initial_password_updated
  end
end
