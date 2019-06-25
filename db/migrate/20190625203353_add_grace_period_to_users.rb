class AddGracePeriodToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :grace_period, :datetime, default: ""
  end

  def down
    remove_column :users, :grace_period
  end
end
