class CreateUsageSamples < ActiveRecord::Migration
  def change
    create_table :usage_samples do |t|

      t.timestamps null: false
    end
  end
end
