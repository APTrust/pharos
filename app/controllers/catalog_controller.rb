class CatalogController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized

  def search
    params[:q] = '%' if params[:q] == '*'
    @results = {}
    authorize current_user
    case params[:object_type]
      when 'object'
        object_search
      when 'file'
        file_search
      when 'item'
        item_search
      when '*'
        generic_search
    end
    filter
    page_and_authorize
    respond_to do |format|
      format.json { render json: {results: @results, next: @next, previous: @previous} }
      format.html { }
    end
  end

  protected

  def page_and_authorize
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    permission_check
    @paged_results = Kaminari.paginate_array(@authorized_results).page(page).per(per_page)
    @next = format_next(page, per_page)
    @previous = format_previous(page, per_page)

  end

  def permission_check
    @authorized_results = []
    consortial_results = []
    institution_results = []
    restricted_results = []
    if current_user.admin?
      @results.each { |key, value| @authorized_results += value }
    else
      @results.each do |key, value|
        consortial_results = value.where(access: 'consortia') unless value == []
        institution_results = value.where('access LIKE ? AND institution_id LIKE ?', 'institution', current_user.institution_id) unless value == []
        restricted_results = value.where('access LIKE ? AND institution_id LIKE ?', 'restricted', current_user.institution_id) unless value == []
        @authorized_results += (consortial_results + institution_results + restricted_results)
      end
    end
  end

  def object_search
    case params[:search_field]
      when 'identifier'
        @results[:objects] = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'alt_identifier'
        @results[:objects] = IntellectualObject.where('alt_identifier LIKE ?', "%#{params[:q]}%")
      when 'bag_name'
        @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
      when 'title'
        @results[:objects] = IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
      when '*'
        @results[:objects] = IntellectualObject.where('identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                             "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def file_search
    case params[:search_field]
      when 'identifier'
        @results[:files] = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'uri'
        @results[:files] = GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
      when '*'
        @results[:files] = GenericFile.where('identifier LIKE ? OR uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def item_search
    case params[:search_field]
      when 'name'
        @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'etag'
        @results[:items] = WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
      when 'object_identifier'
        @results[:items] = WorkItem.where('object_identifier LIKE ?', "%#{params[:q]}%")
      when 'file_identifier'
        @results[:items] = WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
      when '*'
        @results[:items] = WorkItem.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                  "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def generic_search
    case params[:search_field]
      when 'identifier'
        @results[:objects] = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
        @results[:files] = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'alt_identifier'
        @results[:objects] = IntellectualObject.where('alt_identifier LIKE ?', "%#{params[:q]}%")
        @results[:items] = WorkItem.where('object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                      "%#{params[:q]}%", "%#{params[:q]}%")
      when 'bag_name'
        @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'title'
        @results[:objects] = IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
      when 'uri'
        @results[:files] = GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
      when 'name'
        @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'etag'
        @results[:items] = WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
      when 'object_identifier'
        @results[:items] = WorkItem.where('object_identifier LIKE ?', "%#{params[:q]}%")
      when 'file_identifier'
        @results[:items] = WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
      when '*'
        @results[:objects] = IntellectualObject.where('identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                              "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:files] = GenericFile.where('identifier LIKE ? OR uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:items] = WorkItem.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                      "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def filter
    set_filter_values
    filter_results
    set_filter_counts
    set_page_counts
  end

  def set_filter_values
    @statuses = Pharos::Application::PHAROS_STATUSES.values
    @stages = Pharos::Application::PHAROS_STAGES.values
    @actions = Pharos::Application::PHAROS_ACTIONS.values
    @institutions = Array.new
    @accesses = %w(Consortial Institution Restricted)
    @formats = set_formats
    @associations = set_associations
    #@types = ['Intellectual Objects', 'Generic Files', 'Work Items']
    Institution.all.each do |inst|
      @institutions.push(inst.identifier) unless inst.identifier == 'aptrust.org'
    end
    @counts = {}
    @selected = {}
  end

  def filter_results
    filter_by_status if params[:status].present?
    filter_by_stage if params[:stage].present?
    filter_by_action if params[:object_action].present?
    filter_by_institution if params[:institution].present?
    filter_by_access if params[:access].present?
    filter_by_format if params[:file_format].present?
    filter_by_association if params[:association].present?
    filter_by_type if params[:type].present?
  end

  def filter_by_status
    @results[:items] = @results[:items].where(status: params[:status]) unless @results[:items].nil?
    @selected[:status] = params[:status]
  end

  def filter_by_stage
    @results[:items] = @results[:items].where(stage: params[:stage]) unless @results[:items].nil?
    @selected[:stage] = params[:stage]
  end

  def filter_by_action
    @results[:items] = @results[:items].where(action: params[:object_action]) unless @results[:items].nil?
    @selected[:object_action] = params[:object_action]
  end

  def filter_by_institution
    @results[:objects] = @results[:objects].where(institution_id: params[:institution]) unless @results[:objects].nil?
    @results[:files] = @results[:files].where(institution_id: params[:institution]) unless @results[:files].nil?
    @results[:items] = @results[:items].where(institution_id: params[:institution]) unless @results[:items].nil?
    @selected[:institution] = params[:institution]
  end

  def filter_by_access
    @results[:objects] = @results[:objects].where(access: params[:access]) unless @results[:objects].nil?
    @results[:files] = @results[:files].where(access: params[:access]) unless @results[:files].nil?
    @results[:items] = @results[:items].where(access: params[:access]) unless @results[:items].nil?
    @selected[:access] = params[:access]
  end

  def filter_by_format
    #TODO: make sure this is applicable to objects as well as files
    @results[:files] = @results[:files].where(file_format: params[:file_format]) unless @results[:files].nil?
    @results[:objects] = @results[:objects].where(file_format: params[:file_format]) unless @results[:objects].nil?
    @selected[:file_format] = params[:file_format]
  end

  def filter_by_association
    @results[:items] = @results[:items].where('intellectual_object_id LIKE ? OR generic_file_id LIKE ?',
                                              params[:association], params[:association]) unless @results[:items].nil?
    @results[:files] = @results[:files].where(intellectual_object_id: params[:association]) unless @results[:files].nil?
    @selected[:association] = params[:association]
  end

  def filter_by_type
    case params[:type]
      when 'intellectual_object'
        @results[:files] = []
        @results[:items] = []
      when 'generic_file'
        @results[:objects] = []
        @results[:items] = []
      when 'work_item'
        @results[:files] = []
        @results[:objects] = []
    end
    @selected[:type] = params[:type]
  end

  def set_page_counts
    @count = 0
    @results.each { |key, value| @count = @count + value.count }
    if @count == 0
      @second_number = 0
      @first_number = 0
    elsif params[:page].nil?
      @second_number = 10
      @first_number = 1
    else
      @second_number = params[:page].to_i * 10
      @first_number = @second_number.to_i - 9
    end
    @second_number = @count if @second_number > @count
  end

  def set_filter_counts
    @results.each do |key, value|
      if key == 'objects'
        @institutions.each { |institution| @counts[institution] = value.where(institution_id: institution).count }
        @accesses.each { |acc| @counts[acc] = value.where(access: acc).count }
        #@formats.each { |format| @counts[format] = value.where(file_format: format).count }
      elsif key == 'files'
        @formats.each { |format| @counts[format] = value.where(file_format: format).count }
        @institutions.each { |institution| @counts[institution] = value.where(institution_id: institution).count }
        @associations.each { |assc| @counts[assc] = value.where(intellectual_object: assc).count }
        @accesses.each { |acc| @counts[acc] = value.where(access: acc).count }
      elsif key == 'items'
        @statuses.each { |status| @counts[status] = value.where(status: status).count }
        @stages.each { |stage| @counts[stage] = value.where(stage: stage).count }
        @actions.each { |action| @counts[action] = value.where(action: action).count }
        @institutions.each { |institution| @counts[institution] = value.where(institution_id: institution).count }
        @accesses.each { |acc| @counts[acc] = value.where(access: acc).count }
        @associations.each { |assc| @counts[assc] = value.where(intellectual_object: assc).count }
        @associations.each { |assc| @counts[assc] = value.where(generic_file: assc).count }
      end
    end
    @counts['Intellectual Objects'] = @results[:objects].count unless @results[:objects].nil?
    @counts['Generic Files'] = @results[:files].count unless @results[:files].nil?
    @counts['Work Items'] = @results[:items].count unless @results[:items].nil?
  end

  def set_formats
    #TODO: figure out how to set these without looping through all objects
    Array.new
  end

  def set_associations
    #TODO: figure out how to set these without looping through all objects
    Array.new
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def to_boolean(str)
    str == 'true'
  end

  def format_next(page, per_page)
    if @count.to_f / per_page <= page
      nil
    else
      new_page = page + 1
      new_url = "#{request.base_url}/search/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous(page, per_page)
    if page == 1
      nil
    else
      new_page = page - 1
      new_url = "#{request.base_url}/search/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&q=#{params[:q]}" if params[:q].present?
    str = str << "&search_field=#{params[:search_field]}" if params[:search_field].present?
    str = str << "&object_type=#{params[:object_type]}" if params[:object_type].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&object_action=#{params[:object_action]}" if params[:object_action].present?
    str = str << "&stage=#{params[:stage]}" if params[:stage].present?
    str = str << "&status=#{params[:status]}" if params[:status].present?
    str = str << "&access=#{params[:access]}" if params[:access].present?
    str = str << "&format=#{params[:file_format]}" if params[:file_format].present?
    str = str << "&association=#{params[:association]}" if params[:association].present?
    str = str << "&type=#{params[:type]}" if params[:type].present?
    str
  end

end