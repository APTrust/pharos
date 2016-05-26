class AddApiKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :encrypted_api_secret_key, :text
  end
end
