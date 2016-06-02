class UsageSample < ActiveRecord::Base
  serialize :data, Hash

  before_save :collect_sample

  def institution
    unless institution_id
      $stderr.puts 'No institution_id set'
      return nil
    end
    @institution ||= Institution.find(institution_id)
  end

  def institution= inst
    self.institution_id = inst.id
    @institution = inst
  end

  def to_flot
    [created_at.to_i, data['all'] ]
  end

  protected

  def collect_sample
    self.data = institution.bytes_by_format
  end
end
