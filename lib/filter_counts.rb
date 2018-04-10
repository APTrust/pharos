module FilterCounts

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
    @selected[:status] = params[:status]
  end

  def filter_by_stage
    @results = @results.with_stage(params[:stage]) unless @results.nil?
    @selected[:stage] = params[:stage]
  end

  def filter_by_action
    @results = @results.with_action(params[:item_action]) unless @results.nil?
    @selected[:item_action] = params[:item_action]
  end

  def filter_by_institution
    @results = @results.with_institution(params[:institution]) unless @results.nil?
    @selected[:institution] = params[:institution]
  end

  def filter_by_access
    @results = @results.with_access(params[:access]) unless @results.nil?
    @selected[:access] = params[:access]
  end

  def filter_by_format
    @results = @results.with_file_format(params[:file_format]) unless @results.nil?
    @selected[:file_format] = params[:file_format]
  end

  def filter_by_object_association
    @results = @results.where(intellectual_object_id: params[:object_association]) unless @results.nil?
    @selected[:object_association] = params[:object_association]
  end

  def filter_by_file_association
    @results = @results.where(generic_file_id: params[:file_association]) unless @results.nil?
    @selected[:file_association] = params[:file_association]
  end

  def filter_by_state
    params[:state] = 'A' if params[:state].nil?
    unless params[:state] == 'all'
      @results = @results.with_state(params[:state]) unless @results.nil?
      @selected[:state] = params[:state]
    end
  end

  def filter_by_event_type
    @results = @results.with_type(params[:event_type]) unless @results.nil?
    @selected[:event_type] = params[:event_type]
  end

  def filter_by_outcome
    @results = @results.with_outcome(params[:outcome]) unless @results.nil?
    @selected[:outcome] = params[:outcome]
  end

  def filter_by_node
    @results = @results.with_remote_node(params[:remote_node]) unless @results.nil?
    @selected[:remote_node] = params[:remote_node] if params[:remote_node]
  end

  def filter_by_queued
    @results = @results.queued(params[:queued]) unless @results.nil?
    if params[:queued] == 'is_queued'
      @selected[:queued] = 'Has been queued'
    elsif params[:queued] == 'is_not_queued'
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
          @results = @results.order('intellectual_objects.updated_at DESC') unless @results.nil?
        when 'file'
          @results = @results.order('generic_files.updated_at DESC') unless @results.nil?
        when 'event'
          @results = @results.order('premis_events.date_time DESC') unless @results.nil?
        when 'item'
          @results = @results.order('work_items.date DESC') unless @results.nil?
        when 'dpn_item'
          @results = @results.order('dpn_work_items.queued_at DESC') unless @results.nil?
      end
    end
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
  end

  def sort_by_institution
    @results = @results.joins(:institution).order('institutions.name') unless @results.nil?
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
    @queued_counts[:is_queued] = results.queued('is_queued').count
    @queued_counts[:is_not_queued] = results.queued('is_not_queued').count
  end

end
