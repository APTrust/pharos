class PremisEventsOrderedIndex < ActiveRecord::Migration[5.2]
  def change
    # Remove this index that uses the standard ascending sort
    remove_index :premis_events, :date_time

    # Add an index that uses the descending sort, since this is
    # the order in which Rails asks for records. This is especially
    # useful for paged called that order by date_time desc (which
    # includes most of our calls).
    #
    # See https://www.postgresql.org/docs/current/indexes-ordering.html
    #
    # An important special case is ORDER BY in combination with LIMIT n:
    # an explicit sort will have to process all the data to identify
    # the first n rows, but if there is an index matching the ORDER BY,
    # the first n rows can be retrieved directly, without scanning the
    # remainder at all.
    add_index :premis_events, :date_time, order: :desc, name: 'index_premis_events_date_time_desc'
  end
end
