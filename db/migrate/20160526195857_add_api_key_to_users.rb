class AddApiKeyToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :encrypted_api_secret_key, :text
  end
end
