class IndexGfLastFixityCheck < ActiveRecord::Migration[5.2]
  def change
    # The cron job apt_queue_fixity runs a query up to 25 times
    # each hour to queue items due for a fixity check. This index
    # helps when results are ordered by last_fixity_check.
    add_index :generic_files, :last_fixity_check, name: 'ix_gf_last_fixity_check'
  end
end
