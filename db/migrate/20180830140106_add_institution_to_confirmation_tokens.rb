class AddInstitutionToConfirmationTokens < ActiveRecord::Migration[5.2]
  def up
    add_column :confirmation_tokens, :institution_id, :integer
  end

  def down
    remove_column :confirmation_tokens, :institution_id, :integer
  end
end
