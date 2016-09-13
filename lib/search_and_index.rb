module SearchAndIndex

  def initialize_filter_counters
    @selected = {}
    @inst_counts = {}
    @access_counts = {}
    @format_counts = {}
    @io_assc_counts = {}
    @gf_assc_counts = {}
    @status_counts = {}
    @stage_counts = {}
    @action_counts = {}
    @event_type_counts = {}
    @outcome_counts = {}
    @type_counts = {}
  end

  def filter_by_status
    @results[:items] = @results[:items].with_status(params[:status]) unless @results.nil? || @results[:items].nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:objects) unless @results.nil?
    @results.delete(:events) unless @results.nil?
    @items = @items.with_status(params[:status]) unless @items.nil?
    @selected[:status] = params[:status]
  end

  def filter_by_stage
    @results[:items] = @results[:items].with_stage(params[:stage]) unless @results.nil? || @results[:items].nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:objects) unless @results.nil?
    @results.delete(:events) unless @results.nil?
    @items = @items.with_stage(params[:stage]) unless @items.nil?
    @selected[:stage] = params[:stage]
  end

  def filter_by_action
    @results[:items] = @results[:items].with_action(params[:item_action]) unless @results.nil? || @results[:items].nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:objects) unless @results.nil?
    @results.delete(:events) unless @results.nil?
    @items = @items.with_action(params[:item_action]) unless @items.nil?
    @selected[:item_action] = params[:item_action]
  end

  def filter_by_institution
    @results[:objects] = @results[:objects].with_institution(params[:institution]) unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].with_institution(params[:institution]) unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].with_institution(params[:institution]) unless @results.nil? || @results[:items].nil?
    @results[:events] = @results[:events].with_institution(params[:institution]) unless @results.nil? || @results[:events].nil?
    @intellectual_objects = @intellectual_objects.with_institution(params[:institution]) unless @intellectual_objects.nil?
    @generic_files = @generic_files.with_institution(params[:institution]) unless @generic_files.nil?
    @items = @items.with_institution(params[:institution]) unless @items.nil?
    @premis_events = @premis_events.with_institution(params[:institution]) unless @premis_events.nil?
    @selected[:institution] = params[:institution]
  end

  def filter_by_access
    @results[:objects] = @results[:objects].with_access(params[:access]) unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].with_access(params[:access]) unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].with_access(params[:access]) unless @results.nil? || @results[:items].nil?
    @results[:events] = @results[:events].with_access(params[:access]) unless @results.nil? || @results[:events].nil?
    @intellectual_objects = @intellectual_objects.with_access(params[:access]) unless @intellectual_objects.nil?
    @generic_files = @generic_files.with_access(params[:access]) unless @generic_files.nil?
    @items = @items.with_access(params[:access]) unless @items.nil?
    @selected[:access] = params[:access]
  end

  def filter_by_format
    @results[:files] = @results[:files].with_file_format(params[:file_format]) unless @results.nil? || @results[:files].nil?
    @results[:objects] = @results[:objects].with_file_format(params[:file_format]) unless @results.nil? || @results[:objects].nil?
    @results.delete(:items) unless @results.nil? || @results[:items].nil?
    @results.delete(:events) unless @results.nil? || @results[:events].nil?
    @intellectual_objects = @intellectual_objects.with_file_format(params[:file_format]) unless @intellectual_objects.nil?
    @generic_files = @generic_files.with_file_format(params[:file_format]) unless @generic_files.nil?
    @selected[:file_format] = params[:file_format]
  end

  def filter_by_object_association
    @results[:items] = @results[:items].where(intellectual_object_id: params[:object_association]) unless @results.nil? || @results[:items].nil?
    @results[:files] = @results[:files].where(intellectual_object_id: params[:object_association]) unless @results.nil? || @results[:files].nil?
    @results.delete(:objects) unless @results.nil? || @results[:objects].nil?
    @results[:events] = @results[:events].where(intellectual_object_id: params[:object_association]) unless @results.nil? || @results[:events].nil?
    @items = @items.where(intellectual_object_id: params[:object_association]) unless @items.nil?
    @premis_events = @premis_events.where(intellectual_object_id: params[:object_association]) unless @premis_events.nil?
    @selected[:object_association] = params[:object_association]
  end

  def filter_by_file_association
    @results[:items] = @results[:items].where(generic_file_id: params[:file_association]) unless @results.nil? || @results[:items].nil?
    @results.delete(:files) unless @results.nil? || @results[:files].nil?
    @results.delete(:objects) unless @results.nil? || @results[:objects].nil?
    @results[:events] = @results[:events].where(generic_file_id: params[:file_association]) unless @results.nil? || @results[:events].nil?
    @items = @items.where(generic_file_id: params[:file_association]) unless @items.nil?
    @premis_events = @premis_events.where(generic_file_id: params[:file_association]) unless @premis_events.nil?
    @selected[:file_association] = params[:file_association]
  end

  def filter_by_type
    case params[:type]
      when 'Intellectual Objects'
        @results.delete(:files)
        @results.delete(:items)
        @results.delete(:events)
      when 'Generic Files'
        @results.delete(:objects)
        @results.delete(:items)
        @results.delete(:events)
      when 'Work Items'
        @results.delete(:objects)
        @results.delete(:files)
        @results.delete(:events)
      when 'Premis Events'
        @results.delete(:objects)
        @results.delete(:files)
        @results.delete(:items)
    end
    @selected[:type] = params[:type]
  end

  def filter_by_state
    params[:state] = 'A' if params[:state].nil?
    unless params[:state] == 'all'
      @results[:objects] = @results[:objects].with_state(params[:state]) unless @results.nil? || @results[:objects].nil?
      @results[:files] = @results[:files].with_state(params[:state]) unless @results.nil? || @results[:files].nil?
      @results[:items] = @results[:items].with_state(params[:state]) unless @results.nil? || @results[:items].nil?
      @results.delete(:events) unless @results.nil? || @results[:events].nil?
      @intellectual_objects = @intellectual_objects.with_state(params[:state]) unless @intellectual_objects.nil?
      @generic_files = @generic_files.with_state(params[:state]) unless @generic_files.nil?
      @items = @items.with_state(params[:state]) unless @items.nil?
      @selected[:state] = params[:state]
    end
  end

  def filter_by_event_type
    @results.delete(:objects) unless @results.nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:items) unless @results.nil?
    @results[:events] = @results[:events].with_type(params[:event_type]) unless @results.nil? || @results[:events].nil?
    @premis_events = @premis_events.with_type(params[:event_type]) unless @premis_events.nil?
    @selected[:event_type] = params[:event_type]
  end

  def filter_by_outcome
    @results.delete(:objects) unless @results.nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:items) unless @results.nil?
    @results[:events] = @results[:events].with_outcome(params[:outcome]) unless @results.nil? || @results[:events].nil?
    @premis_events = @premis_events.with_outcome(params[:outcome]) unless @premis_events.nil?
    @selected[:outcome] = params[:outcome]
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
    @results[:objects] = @results[:objects].order('created_at DESC') unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].order('created_at DESC') unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].order('date DESC') unless @results.nil? || @results[:items].nil?
    @results[:events] = @results[:events].order('date_time DESC') unless @results.nil? || @results[:events].nil?
    @intellectual_objects = @intellectual_objects.order('created_at DESC') unless @intellectual_objects.nil?
    @generic_files = @generic_files.order('created_at DESC') unless @generic_files.nil?
    @items = @items.order('date DESC') unless @items.nil?
    @premis_events = @premis_events.order('date_time DESC') unless @premis_events.nil?
  end

  def sort_by_name
    @results[:objects] = @results[:objects].order('title') unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].order('uri') unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].order('name') unless @results.nil? || @results[:items].nil?
    @results[:events] = @results[:events].order('identifier').reverse_order unless @results.nil? || @results[:events].nil?
    @intellectual_objects = @intellectual_objects.order('bag_name').reverse_order unless @intellectual_objects.nil?
    @generic_files = @generic_files.order('uri') unless @generic_files.nil?
    @items = @items.order('name') unless @items.nil?
    @premis_events = @premis_events.order('identifier') unless @premis_events.nil?
  end

  def sort_by_institution
    @results[:objects] = @results[:objects].joins(:institution).order('institutions.name') unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].joins(:institution).order('institutions.name') unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].joins(:institution).order('institutions.name') unless @results.nil? || @results[:items].nil?
    @results[:events] = @results[:events].joins(:institution).order('institutions.name') unless @results.nil? || @results[:events].nil?
    @intellectual_objects = @intellectual_objects.joins(:institution).order('institutions.name') unless @intellectual_objects.nil?
    @generic_files = @generic_files.joins(:institution).order('institutions.name') unless @generic_files.nil?
    @items = @items.joins(:institution).order('institutions.name') unless @items.nil?
    @premis_events = @premis_events.joins(:institution).order('institutions.name') unless @premis_events.nil?
  end

  def set_inst_count(results)
    unless @institutions.nil?
      @institutions.each do |institution|
        @inst_counts[institution].nil? ?
            @inst_counts[institution] = results.with_institution(institution).count :
            @inst_counts[institution] = @inst_counts[institution] + results.with_institution(institution).count
      end
    end
  end

  def set_access_count(results)
    unless @accesses.nil?
      @accesses.each do |acc|
        @access_counts[acc].nil? ?
            @access_counts[acc] = results.with_access(acc).count :
            @access_counts[acc] = @access_counts[acc] + results.with_access(acc).count
      end
    end
  end

  def set_format_count(results)
    unless @formats.nil?
      @formats.each do |format|
        @format_counts[format].nil? ?
            @format_counts[format] = results.with_file_format(format).count :
            @format_counts[format] = @format_counts[format] + results.with_file_format(format).count
      end
    end
  end

  def set_io_assc_count(results)
    unless @object_associations.nil?
      @object_associations.each do |assc|
        @io_assc_counts[assc].nil? ?
            @io_assc_counts[assc] = results.where(intellectual_object_id: assc).count :
            @io_assc_counts[assc] = @io_assc_counts[assc] + results.where(intellectual_object_id: assc).count
      end
    end
  end

  def set_gf_assc_count(results)
    unless @file_associations.nil?
      @file_associations.each do |assc|
        @gf_assc_counts[assc].nil? ?
            @gf_assc_counts[assc] = results.where(generic_file_id: assc).count :
            @gf_assc_counts[assc] = @gf_assc_counts[assc] + results.where(generic_file_id: assc).count
      end
    end
  end

  def set_status_count(results)
    unless @statuses.nil?
      @statuses.each do |status|
        @status_counts[status].nil? ?
            @status_counts[status] = results.where(status: status).count :
            @status_counts[status] = @status_counts[status] + results.where(status: status).count
      end
    end
  end

  def set_stage_count(results)
    unless @stages.nil?
      @stages.each do |stage|
        @stage_counts[stage].nil? ?
            @stage_counts[stage] = results.where(stage: stage).count :
            @stage_counts[stage] = @stage_counts[stage] + results.where(stage: stage).count
      end
    end
  end

  def set_action_count(results)
    unless @actions.nil?
      @actions.each do |action|
        @action_counts[action].nil? ?
            @action_counts[action] = results.where(action: action).count :
            @action_counts[action] = @action_counts[action] + results.where(action: action).count
      end
    end
  end

  def set_event_type_count(results)
    unless @event_types.nil?
      @event_types.each do |type|
        @event_type_counts[type].nil? ?
            @event_type_counts[type] = results.where(event_type: type).count :
            @event_type_counts[type] = @event_type_counts[type] + results.where(event_type: type).count
      end
    end
  end

  def set_outcome_count(results)
    unless @outcomes.nil?
      @outcomes.each do |outcome|
        @outcome_counts[outcome].nil? ?
            @outcome_counts[outcome] = results.where(outcome: outcome).count :
            @outcome_counts[outcome] = @outcome_counts[outcome] + results.where(outcome: outcome).count
      end
    end
  end

  def set_page_counts(count)
    @count = count
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    if @count == 0
      @second_number = 0
      @first_number = 0
    else
      @second_number = params[:page].to_i * params[:per_page].to_i
      @first_number = (@second_number.to_i - params[:per_page].to_i) + 1
    end
    @second_number = @count if @second_number > @count
  end

  def page_results(results)
    @page = params[:page].to_i
    @per_page = params[:per_page].to_i
    @paged_results = Kaminari.paginate_array(results).page(@page).per(@per_page)
    @next = format_next
    @current = format_current
    @previous = format_previous
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def to_boolean(str)
    str == 'true'
  end

  def format_current
    path = request.fullpath.split('?').first
    new_url = "#{request.base_url}#{path}?page=#{@page}&per_page=#{@per_page}"
    new_url = add_params(new_url)
    new_url
  end

  def format_next
    if @count.to_f / @per_page <= @page
      nil
    else
      path = request.fullpath.split('?').first
      new_page = @page + 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{@per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous
    if @page == 1
      nil
    else
      path = request.fullpath.split('?').first
      new_page = @page - 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{@per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&q=#{URI.escape(params[:q])}" if params[:q].present?
    str = str << "&search_field=#{URI.escape(params[:search_field])}" if params[:search_field].present?
    str = str << "&object_type=#{URI.escape(params[:object_type])}" if params[:object_type].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&item_action=#{params[:item_action]}" if params[:item_action].present?
    str = str << "&stage=#{params[:stage]}" if params[:stage].present?
    str = str << "&status=#{params[:status]}" if params[:status].present?
    str = str << "&access=#{params[:access]}" if params[:access].present?
    str = str << "&file_format=#{params[:file_format]}" if params[:file_format].present?
    str = str << "&file_association=#{params[:file_association]}" if params[:file_association].present?
    str = str << "&object_association=#{params[:object_association]}" if params[:object_association].present?
    str = str << "&type=#{params[:type]}" if params[:type].present?
    str = str << "&sort=#{params[:sort]}" if params[:sort].present?
    str = str << "&state=#{params[:state]}" if params[:state].present?
    str = str << "&institution_identifier=#{params[:institution_identifier]}" if params[:institution_identifier].present?
    str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
    str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
    str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
    str = str << "&node=#{params[:node]}" if params[:node].present?
    str = str << "&needs_admin_review=#{params[:needs_admin_review]}" if params[:needs_admin_review].present?
    str = str << "&event_type=#{params[:event_type]}" if params[:event_type].present?
    str = str << "&outcome=#{params[:outcome]}" if params[:outcome].present?
    str
  end
end