class AddConfirmationFlagToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :account_confirmed, :boolean, default: true
  end

  def down
    remove_column :users, :account_confirmed
  end
end
