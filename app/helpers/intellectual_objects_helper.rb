module IntellectualObjectsHelper
  def format_display(format)
    format == 'all' ? 'Total Content Upload' : format
  end

  def format_class(format)
    format.split('/')[-1].downcase.gsub(/\s/, '_') + '_label' unless format.split('/')[-1].nil?
  end

  def query_has_constraints?(localized_params = params)
    !(localized_params[:q].blank? and localized_params[:f].blank?)
  end

  def search_action_url options = {}
    institution_intellectual_objects_path(institution_identifier: params[:identifier])
  end
end
