class CreateConfirmationToken < ActiveRecord::Migration[5.1]
  def change
    create_table :confirmation_tokens do |t|
      t.string :token, default: nil
      t.integer :intellectual_object_id, default: nil
    end
  end
end
