module IntellectualObjectsHelper
  def format_display(format)
    format == 'all' ? 'Total Content Upload' : format
  end

  def format_class(format)
    format.split('/')[-1].downcase.gsub(/\s/, '_') + '_label' unless format.split('/')[-1].nil?
  end
end
