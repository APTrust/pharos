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
    @queued_counts = {}
    @node_counts = {}
  end

  def filter_by_status
    @results = @results.with_status(params[:status]) unless @results.nil?
    @items = @items.with_status(params[:status]) unless @items.nil?
    @selected[:status] = params[:status]
  end

  def filter_by_stage
    @results = @results.with_stage(params[:stage]) unless @results.nil?
    @items = @items.with_stage(params[:stage]) unless @items.nil?
    @selected[:stage] = params[:stage]
  end

  def filter_by_action
    @results = @results.with_action(params[:item_action]) unless @results.nil?
    @items = @items.with_action(params[:item_action]) unless @items.nil?
    @selected[:item_action] = params[:item_action]
  end

  def filter_by_institution
    @results = @results.with_institution(params[:institution]) unless @results.nil?
    @intellectual_objects = @intellectual_objects.with_institution(params[:institution]) unless @intellectual_objects.nil?
    @generic_files = @generic_files.with_institution(params[:institution]) unless @generic_files.nil?
    @items = @items.with_institution(params[:institution]) unless @items.nil?
    @premis_events = @premis_events.with_institution(params[:institution]) unless @premis_events.nil?
    @selected[:institution] = params[:institution]
  end

  def filter_by_access
    @results = @results.with_access(params[:access]) unless @results.nil?
    @intellectual_objects = @intellectual_objects.with_access(params[:access]) unless @intellectual_objects.nil?
    @generic_files = @generic_files.with_access(params[:access]) unless @generic_files.nil?
    @items = @items.with_access(params[:access]) unless @items.nil?
    @selected[:access] = params[:access]
  end

  def filter_by_format
    @results = @results.with_file_format(params[:file_format]) unless @results.nil?
    @intellectual_objects = @intellectual_objects.with_file_format(params[:file_format]) unless @intellectual_objects.nil?
    @generic_files = @generic_files.with_file_format(params[:file_format]) unless @generic_files.nil?
    @selected[:file_format] = params[:file_format]
  end

  def filter_by_object_association
    @results = @results.where(intellectual_object_id: params[:object_association]) unless @results.nil?
    @items = @items.where(intellectual_object_id: params[:object_association]) unless @items.nil?
    @premis_events = @premis_events.where(intellectual_object_id: params[:object_association]) unless @premis_events.nil?
    @selected[:object_association] = params[:object_association]
  end

  def filter_by_file_association
    @results = @results.where(generic_file_id: params[:file_association]) unless @results.nil?
    @items = @items.where(generic_file_id: params[:file_association]) unless @items.nil?
    @premis_events = @premis_events.where(generic_file_id: params[:file_association]) unless @premis_events.nil?
    @selected[:file_association] = params[:file_association]
  end

  def filter_by_state
    params[:state] = 'A' if params[:state].nil?
    unless params[:state] == 'all'
      @results = @results.with_state(params[:state]) unless @results.nil?
      @intellectual_objects = @intellectual_objects.with_state(params[:state]) unless @intellectual_objects.nil?
      @generic_files = @generic_files.with_state(params[:state]) unless @generic_files.nil?
      @items = @items.with_state(params[:state]) unless @items.nil?
      @selected[:state] = params[:state]
    end
  end

  def filter_by_event_type
    @results = @results.with_type(params[:event_type]) unless @results.nil?
    @premis_events = @premis_events.with_type(params[:event_type]) unless @premis_events.nil?
    @selected[:event_type] = params[:event_type]
  end

  def filter_by_outcome
    @results = @results.with_outcome(params[:outcome]) unless @results.nil?
    @premis_events = @premis_events.with_outcome(params[:outcome]) unless @premis_events.nil?
    @selected[:outcome] = params[:outcome]
  end

  def filter_by_node
    @results = @results.with_remote_node(params[:remote_node]) unless @results.nil?
    @dpn_items = @dpn_items.with_remote_node(params[:remote_node]) unless @dpn_items.nil?
    @selected[:remote_node] = params[:remote_node] if params[:remote_node]
  end

  def filter_by_queued
    if params[:queued] == 'is_queued'
      @results = @results.is_queued('true') unless @results.nil?
      @dpn_items = @dpn_items.is_queued('true') unless @dpn_items.nil?
      @selected[:queued] = 'Has been queued'
    elsif params[:queued] == 'is_not_queued'
      @results = @results.is_not_queued('true') unless @results.nil?
      @dpn_items = @dpn_items.is_not_queued('true') unless @dpn_items.nil?
      @selected[:queued] = 'Has not been queued'
    end
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
    if @result_type
      case @result_type
        when 'object'
          @results = @results.order('updated_at DESC') unless @results.nil?
        when 'file'
          @results = @results.order('updated_at DESC') unless @results.nil?
        when 'event'
          @results = @results.order('date_time DESC') unless @results.nil?
        when 'item'
          @results = @results.order('date DESC') unless @results.nil?
        when 'dpn_item'
          @results = @results.order('queued_at DESC') unless @results.nil?
      end
    end
    @intellectual_objects = @intellectual_objects.order('created_at DESC') unless @intellectual_objects.nil?
    @generic_files = @generic_files.order('created_at DESC') unless @generic_files.nil?
    @items = @items.order('date DESC') unless @items.nil?
    @premis_events = @premis_events.order('date_time DESC') unless @premis_events.nil?
  end

  def sort_by_name
    if @result_type
      case @result_type
        when 'object'
          @results = @results.order('title') unless @results.nil?
        when 'file'
          @results = @results.order('identifier') unless @results.nil?
        when 'event'
          @results = @results.order('identifier').reverse_order unless @results.nil?
        when 'item'
          @results = @results.order('name') unless @results.nil?
        when 'dpn_item'
          @results = @results.order ('identifier') unless @results.nil?
      end
    end
    @intellectual_objects = @intellectual_objects.order('bag_name').reverse_order unless @intellectual_objects.nil?
    @generic_files = @generic_files.order('uri') unless @generic_files.nil?
    @items = @items.order('name') unless @items.nil?
    @premis_events = @premis_events.order('identifier') unless @premis_events.nil?
  end

  def sort_by_institution
    @results = @results.joins(:institution).order('institutions.name') unless @results.nil?
    @intellectual_objects = @intellectual_objects.joins(:institution).order('institutions.name') unless @intellectual_objects.nil?
    @generic_files = @generic_files.joins(:institution).order('institutions.name') unless @generic_files.nil?
    @items = @items.joins(:institution).order('institutions.name') unless @items.nil?
    @premis_events = @premis_events.joins(:institution).order('institutions.name') unless @premis_events.nil?
  end

  # TODO: Discuss needs, to see which code we keep.
  # In most cases below, we'll want to keep the uncommented code.
  def set_inst_count(results, obj_type)
    unless @institutions.nil?
      # Can't do group by for files, because we need to join to intel_obj table
      if obj_type == :files
        @institutions.each do |institution|
          @inst_counts[institution].nil? ?
          @inst_counts[institution] = results.with_institution(institution).count :
            @inst_counts[institution] = @inst_counts[institution] + results.with_institution(institution).count
        end
      else
        counts = results.group(:institution_id).count
        counts.each do |id, number|
          #@inst_counts[id].nil? ? @inst_counts[id] = number : @inst_counts[id] += number
          @inst_counts[id] = number
        end
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

  def set_format_count(results, obj_type)
    unless @formats.nil?
      if obj_type == :object
        @formats.each do |format|
          @format_counts[format].nil? ?
          @format_counts[format] = results.with_file_format(format).count :
            @format_counts[format] = @format_counts[format] + results.with_file_format(format).count
        end
      else
        counts = results.group(:file_format).order(:file_format).count
        counts.each do |format, number|
          @format_counts[format].nil? ? @format_counts[format] = number : @format_counts[format] += number
        end
      end
    end
  end

  def set_status_count(results)
    unless @statuses.nil?
      counts = results.group(:status).order(:status).count
      counts.each do |status, number|
        @status_counts[status].nil? ? @status_counts[status] = number : @status_counts[status] += number
      end
    end
  end

  def set_stage_count(results)
    unless @stages.nil?
      counts = results.group(:stage).order(:stage).count
      counts.each do |stage, number|
        @stage_counts[stage].nil? ? @stage_counts[stage] = number : @stage_counts[stage] += number
      end
    end
  end

  def set_action_count(results)
    unless @actions.nil?
      counts = results.group(:action).order(:action).count
      counts.each do |action, number|
        @action_counts[action].nil? ? @action_counts[action] = number : @action_counts[action] += number
      end
    end
  end

  def set_event_type_count(results)
    unless @event_types.nil?
      counts = results.group(:event_type).order(:event_type).count
      counts.each do |event_type, number|
        @event_type_counts[event_type].nil? ? @event_type_counts[event_type] = number :
          @event_type_counts[event_type] += number
      end
    end
  end

  def set_outcome_count(results)
    unless @outcomes.nil?
      counts = results.group(:outcome).order(:outcome).count
      counts.each do |outcome, number|
        @outcome_counts[outcome].nil? ? @outcome_counts[outcome] = number :
          @outcome_counts[outcome] += number
      end
    end
  end

  def set_node_count(results)
    unless @nodes.nil?
      begin
        counts = results.group(:remote_node).count
        counts.each do |node, number|
          @node_counts[node].nil? ? @node_counts[node] = number : @node_counts[node] +=number
        end
      rescue Exception => ex
        logger.error ex.backtrace
      end
    end
  end

  def set_queued_count(results)
    @queued_counts[:is_queued] = results.is_queued('true').count
    @queued_counts[:is_not_queued] = results.is_not_queued('true').count
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
    #@paged_results = Kaminari.paginate_array(results).page(@page).per(@per_page)
    @paged_results = results.page(@page).per(@per_page)
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
    #path = request.fullpath.split('?').first
    #new_url = "#{request.base_url}#{path}?page=#{@page}&per_page=#{@per_page}"
    #new_url = add_params(new_url)
    params[:page] = @page
    params[:per_page] = @per_page
    new_url = url_for(params.permit(Pharos::Application::PARAMS_HASH))
    new_url
  end

  def format_next
    if @count.to_f / @per_page <= @page
      nil
    else
      #path = request.fullpath.split('?').first
      new_page = @page + 1
      params[:page] = new_page
      params[:per_page] = @per_page
      new_url = url_for(params.permit(Pharos::Application::PARAMS_HASH))
      #new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{@per_page}"
      #new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous
    if @page == 1
      nil
    else
      #path = request.fullpath.split('?').first
      new_page = @page - 1
      params[:page] = new_page
      params[:per_page] = @per_page
      new_url = url_for(params.permit(Pharos::Application::PARAMS_HASH))
      #new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{@per_page}"
      #new_url = add_params(new_url)
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
    str = str << "&not_checked_since=#{params[:not_checked_since]}" if params[:not_checked_since].present?
    str = str << "&identifier_like=#{params[:identifier_like]}" if params[:identifier_like].present?
    str
  end
end
