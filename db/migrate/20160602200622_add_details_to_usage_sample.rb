class AddDetailsToUsageSample < ActiveRecord::Migration[4.2]
  def change
    add_column :usage_samples, :institution_id, :string
    add_column :usage_samples, :data, :text
  end
end
