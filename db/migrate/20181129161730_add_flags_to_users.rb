class AddFlagsToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :enabled_two_factor, :boolean, default: false
    add_column :users, :confirmed_two_factor, :boolean, default: false
  end

  def down
    remove_column :users, :enabled_two_factor
    remove_column :users, :confirmed_two_factor
  end
end
