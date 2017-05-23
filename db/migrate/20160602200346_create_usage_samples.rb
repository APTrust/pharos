class CreateUsageSamples < ActiveRecord::Migration[4.2]
  def change
    create_table :usage_samples do |t|

      t.timestamps null: false
    end
  end
end
