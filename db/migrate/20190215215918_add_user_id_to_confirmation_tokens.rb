class AddUserIdToConfirmationTokens < ActiveRecord::Migration[5.2]
  def up
    add_column :confirmation_tokens, :user_id, :integer
  end

  def down
    remove_column :confirmation_tokens, :user_id, :integer
  end
end
