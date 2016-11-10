class FixDpnStateAgain < ActiveRecord::Migration
  def change
    # This is the same as the previous migration, but we have to
    # explicitly specify a limit, because if we don't, this
    # Rails bug will forcibly add a limit of 255 characters,
    # which defeats the whole point of having a text field.
    # WTF, Rails! Bug: https://github.com/rails/rails/issues/19001
    # So this limit is 100 MB, which we better not ever hit.
    change_column :dpn_work_items, :state, :text, default: nil, limit: 104857600
  end
end
