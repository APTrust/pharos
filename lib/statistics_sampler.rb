module StatisticsSampler

  # Record a list of all the current statistics in the database
  def self.record_current_statistics
    Institution.all.each do |inst|
      UsageSample.create(institution_id: inst.id)
    end
  end

end