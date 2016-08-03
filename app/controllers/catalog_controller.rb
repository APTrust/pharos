class CatalogController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized

  def search
    params[:q] = '%' if params[:q] == '*'
    @results = {}
    authorize current_user
    case params[:object_type]
      when 'Intellectual Objects'
        object_search
      when 'Generic Files'
        file_search
      when 'Work Items'
        item_search
      when 'All Types'
        generic_search
      when '*'
        generic_search
    end

    #TODO: add way to filter by active/deleted/etc
    filter
    sort
    page_and_authorize
    respond_to do |format|
      format.json { render json: {results: @paged_results, next: @next, previous: @previous} }
      format.html { }
    end
  end

  protected

  def page_and_authorize
    @page = params[:page].to_i
    @per_page = params[:per_page].to_i
    permission_check
    @paged_results = Kaminari.paginate_array(@authorized_results).page(@page).per(@per_page)
    @next = format_next
    @current = format_current
    @previous = format_previous
  end

  def permission_check
    @authorized_results = []
    if current_user.admin?
      @results.each { |key, value| @authorized_results += value }
    else
      @results.each do |key, value|
        consortial_results = value.where(access: 'consortia')
        institution_results = value.where('access LIKE ? AND institution_id LIKE ?', 'institution', current_user.institution_id)
        restricted_results = value.where('access LIKE ? AND institution_id LIKE ?', 'restricted', current_user.institution_id)
        @authorized_results += (consortial_results + institution_results + restricted_results)
      end
    end
  end

  def object_search
    case params[:search_field]
      when 'Identifier'
        @results[:objects] = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'Alternate Identifier'
        @results[:objects] = IntellectualObject.where('alt_identifier LIKE ?', "%#{params[:q]}%")
      when 'Bag Name'
        @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
      when 'Title'
        @results[:objects] = IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
      when 'All Fields'
        @results[:objects] = IntellectualObject.where('identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                             "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def file_search
    case params[:search_field]
      when 'Identifier'
        @results[:files] = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'URI'
        @results[:files] = GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
      when 'All Fields'
        @results[:files] = GenericFile.where('identifier LIKE ? OR uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def item_search
    case params[:search_field]
      when 'Name'
        @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'Etag'
        @results[:items] = WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
      when 'Intellectual Object Identifier'
        @results[:items] = WorkItem.where('object_identifier LIKE ?', "%#{params[:q]}%")
      when 'Generic File Identifier'
        @results[:items] = WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
      when 'All Fields'
        @results[:items] = WorkItem.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                  "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def generic_search
    case params[:search_field]
      when 'Identifier'
        @results[:objects] = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
        @results[:files] = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'Alternate Identifier'
        @results[:objects] = IntellectualObject.where('alt_identifier LIKE ?', "%#{params[:q]}%")
        @results[:items] = WorkItem.where('object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                      "%#{params[:q]}%", "%#{params[:q]}%")
      when 'Bag Name'
        @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'Title'
        @results[:objects] = IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
      when 'URI'
        @results[:files] = GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
      when 'Name'
        @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'Etag'
        @results[:items] = WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
      when 'Intellectual Object Identifier'
        @results[:items] = WorkItem.where('object_identifier LIKE ?', "%#{params[:q]}%")
        @results[:objects] = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'Generic File Identifier'
        @results[:items] = WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
        @results[:files] = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'All Fields'
        @results[:objects] = IntellectualObject.where('identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                              "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:files] = GenericFile.where('identifier LIKE ? OR uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:items] = WorkItem.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                      "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def filter
    @selected = {}
    filter_results
    set_filter_values
    set_filter_counts
    set_page_counts
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
    filter_by_state if params[:state].present?
  end

  def filter_by_status
    @results[:items] = @results[:items].where(status: params[:status]) unless @results[:items].nil?
    @results.delete(:files)
    @results.delete(:objects)
    @selected[:status] = params[:status]
  end

  def filter_by_stage
    @results[:items] = @results[:items].where(stage: params[:stage]) unless @results[:items].nil?
    @results.delete(:files)
    @results.delete(:objects)
    @selected[:stage] = params[:stage]
  end

  def filter_by_action
    @results[:items] = @results[:items].where(action: params[:object_action]) unless @results[:items].nil?
    @results.delete(:files)
    @results.delete(:objects)
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
    #@results[:objects] = @results[:objects].where(file_format: params[:file_format]) unless @results[:objects].nil?
    @results.delete(:files)
    @results.delete(:objects)
    @selected[:file_format] = params[:file_format]
  end

  def filter_by_association
    @results[:items] = @results[:items].where('intellectual_object_id LIKE ? OR generic_file_id LIKE ?',
                                              params[:association], params[:association]) unless @results[:items].nil?
    @results[:files] = @results[:files].where(intellectual_object_id: params[:association]) unless @results[:files].nil?
    @results[:objects] = @results[:objects].where(id: params[:association])
    @selected[:association] = params[:association]
  end

  def filter_by_type
    case params[:type]
      when 'intellectual_object'
        @results.delete(:files)
        @results.delete(:items)
      when 'generic_file'
        @results.delete(:objects)
        @results.delete(:items)
      when 'work_item'
        @results.delete(:objects)
        @results.delete(:files)
    end
    @selected[:type] = params[:type]
  end

  def filter_by_state
    params[:state] = 'A' if params[:state].nil?
    unless params[:state] == 'all'
      @results[:objects] = @results[:objects].where(state: params[:state]) unless @results[:objects].nil?
      @results[:files] = @results[:files].where(state: params[:state]) unless @results[:files].nil?
      @results.delete(:items)
      @selected[:state] = params[:state]
    end
  end

  def set_filter_values
    @statuses = @results[:items].distinct.pluck(:status) unless @results[:items].nil?
    @stages = @results[:items].distinct.pluck(:stage) unless @results[:items].nil?
    @actions = @results[:items].distinct.pluck(:action) unless @results[:items].nil?
    io_inst = @results[:objects].distinct.pluck(:institution_id) unless @results[:objects].nil?
    gf_inst = @results[:files].distinct.pluck(:institution_id) unless @results[:files].nil?
    wi_inst = @results[:items].distinct.pluck(:institution_id) unless @results[:items].nil?
    @institutions = io_inst | gf_inst | wi_inst
    @accesses = %w(consortia institution restricted)
    @formats = GenericFile.distinct.pluck(:file_format)
    file_associations = GenericFile.distinct.pluck(:intellectual_object_id)
    item_io_associations = WorkItem.distinct.pluck(:intellectual_object_id)
    item_gf_associations = WorkItem.distinct.pluck(:generic_file_id)
    deduped_io_associations = file_associations | item_io_associations
    @associations = deduped_io_associations + item_gf_associations
  end

  def set_page_counts
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    @count = 0
    @results.each { |key, value| @count = @count + value.count }
    if @count == 0
      @second_number = 0
      @first_number = 0
    elsif params[:page].nil?
      @second_number = 10
      @first_number = 1
    else
      @second_number = params[:page].to_i * params[:per_page].to_i
      @first_number = (@second_number.to_i - params[:per_page].to_i) + 1
    end
    @second_number = @count if @second_number > @count
  end

  def sort
    case params[:sort]
      when 'date'
        sort_by_date
      when 'name'
        sort_by_name
      when 'institution'
        sort_by_institution
    end
  end

  def sort_by_date
    @results[:objects] = @results[:objects].order('created_at').reverse_order unless @results[:objects].nil?
    @results[:files] = @results[:files].order('created').reverse_order  unless @results[:files].nil?
    @results[:items] = @results[:items].order('date').reverse_order  unless @results[:items].nil?
    @selected[:sort] = params[:sort]
  end

  def sort_by_name
    @results[:objects] = @results[:objects].order('bag_name') unless @results[:objects].nil?
    @results[:files] = @results[:files].order('uri')  unless @results[:files].nil?
    @results[:items] = @results[:items].order('name')  unless @results[:items].nil?
    @selected[:sort] = params[:sort]
  end

  def sort_by_institution
    @results[:objects] = @results[:objects].order('institution_id').reverse_order unless @results[:objects].nil?
    @results[:files] = @results[:files].order('institution_id').reverse_order  unless @results[:files].nil?
    @results[:items] = @results[:items].order('institution_id').reverse_order  unless @results[:items].nil?
    @selected[:sort] = params[:sort]
  end

  def set_filter_counts
    @counts = {}
    @results.each do |key, value|
      if key == :objects
        set_inst_count(value)
        set_access_count(value)
        #set_format_count(value)
      elsif key == :files
        set_format_count(value)
        set_inst_count(value)
        set_io_assc_count(value)
        set_access_count(value)
      elsif key == :items
        set_status_count(value)
        set_stage_count(value)
        set_action_count(value)
        set_inst_count(value)
        set_access_count(value)
        set_io_assc_count(value)
        set_gf_assc_count(value)
      end
    end
    @counts['Intellectual Objects'] = @results[:objects].count unless @results[:objects].nil?
    @counts['Generic Files'] = @results[:files].count unless @results[:files].nil?
    @counts['Work Items'] = @results[:items].count unless @results[:items].nil?
  end

  def set_inst_count(value)
    #Book.select('type, count(*)').where(:type => ["Banking","IT"]).group(:type)
    inst_list = ''
    @institutions.each do |inst|
      if inst_list == ''
        inst_list = "#{inst}"
      else
        inst_list = "#{inst_list} , #{inst}"
      end
    end
    @inst_facet = @results[:objects].select('institution_id, count(*)').where(institution_id: [inst_list]).group(:institution_id)
    unless @institutions.nil?
      @institutions.each do |institution|
        @counts[institution].nil? ?
            @counts[institution] = value.where(institution_id: institution).count :
            @counts[institution] = @counts[institution] + value.where(institution_id: institution).count
      end
    end
  end

  def set_access_count(value)
    unless @accesses.nil?
      @accesses.each do |acc|
        @counts[acc].nil? ?
            @counts[acc] = value.where(access: acc).count :
            @counts[acc] = @counts[acc] + value.where(access: acc).count
      end
    end
  end

  def set_format_count(value)
    unless @formats.nil?
      @formats.each do |format|
        @counts[format].nil? ?
            @counts[format] = value.where(file_format: format).count :
            @counts[format] = @counts[format] + value.where(file_format: format).count
      end
    end
  end

  def set_io_assc_count(value)
    unless @associations.nil?
      @associations.each do |assc|
        @counts[assc].nil? ?
            @counts[assc] = value.where(intellectual_object_id: assc).count :
            @counts[assc] = @counts[assc] + value.where(intellectual_object_id: assc).count
      end
    end
  end

  def set_gf_assc_count(value)
    unless @associations.nil?
      @associations.each do |assc|
        @counts[assc].nil? ?
            @counts[assc] = value.where(generic_file_id: assc).count :
            @counts[assc] = @counts[assc] + value.where(generic_file_id: assc).count
      end
    end
  end

  def set_status_count(value)
    unless @statuses.nil?
      @statuses.each do |status|
        @counts[status].nil? ?
            @counts[status] = value.where(status: status).count :
            @counts[status] = @counts[status] + value.where(status: status).count
      end
    end
  end

  def set_stage_count(value)
    unless @stages.nil?
      @stages.each do |stage|
        @counts[stage].nil? ?
            @counts[stage] = value.where(stage: stage).count :
            @counts[stage] = @counts[stage] + value.where(stage: stage).count
      end
    end
  end

  def set_action_count(value)
    unless @actions.nil?
      @actions.each do |action|
        @counts[action].nil? ?
            @counts[action] = value.where(action: action).count :
            @counts[action] = @counts[action] + value.where(action: action).count
      end
    end
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def to_boolean(str)
    str == 'true'
  end

  def format_next
    if @count.to_f / @per_page <= @page
      nil
    else
      new_page = @page + 1
      new_url = "#{request.base_url}/search/?page=#{new_page}&per_page=#{@per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous
    if @page == 1
      nil
    else
      new_page = @page - 1
      new_url = "#{request.base_url}/search/?page=#{new_page}&per_page=#{@per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_current
    new_url = "#{request.base_url}/search/?page=#{@page}&per_page=#{@per_page}"
    new_url = add_params(new_url)
    new_url
  end

  def add_params(str)
    str = str << "&q=#{URI.escape(params[:q])}" if params[:q].present?
    str = str << "&search_field=#{URI.escape(params[:search_field])}" if params[:search_field].present?
    str = str << "&object_type=#{URI.escape(params[:object_type])}" if params[:object_type].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&object_action=#{params[:object_action]}" if params[:object_action].present?
    str = str << "&stage=#{params[:stage]}" if params[:stage].present?
    str = str << "&status=#{params[:status]}" if params[:status].present?
    str = str << "&access=#{params[:access]}" if params[:access].present?
    str = str << "&format=#{params[:file_format]}" if params[:file_format].present?
    str = str << "&association=#{params[:association]}" if params[:association].present?
    str = str << "&type=#{params[:type]}" if params[:type].present?
    str = str << "&type=#{params[:sort]}" if params[:sort].present?
    str = str << "&type=#{params[:state]}" if params[:state].present?
    str
  end

end