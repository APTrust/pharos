class AddAuthyStatusToUsers < ActiveRecord::Migration[5.2]
  def self.up
    change_table :users do |t|
      t.string    :authy_status
    end
  end

  def self.down
    change_table :users do |t|
      t.remove :authy_status
    end
  end
end
