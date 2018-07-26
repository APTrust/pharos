class AddDeactivatedAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :deactivated_at, :datetime, default: nil
  end
end
