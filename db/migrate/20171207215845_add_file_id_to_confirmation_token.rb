class AddFileIdToConfirmationToken < ActiveRecord::Migration[5.1]
  def change
    add_column :confirmation_tokens, :generic_file_id, :integer, default: nil
    add_column :emails, :generic_file_id, :integer, default: nil
  end
end
