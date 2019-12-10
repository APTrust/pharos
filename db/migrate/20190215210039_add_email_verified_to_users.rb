class AddEmailVerifiedToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :email_verified, :boolean, default: false
  end

  def down
    remove_column :users, :email_verified
  end
end
