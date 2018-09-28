module FilterCounts

  def get_institution_counts(results)
    @selected[:institution] = params[:institution] if params[:institution]
    counts = results.group(:institution_id).count
    @inst_counts = {}
    counts.each do |key, value|
      name = Institution.find(key).name
      @inst_counts[name] = [key, value]
    end
    @inst_counts = Hash[@inst_counts.sort]
  end

  def get_event_institution_counts(results)
    @selected[:institution] = params[:institution] if params[:institution]
    params[:institution] ? @institutions = [params[:institution]] : @institutions = Institution.all.pluck(:id)
    @sorted_institutions = {}
    @institutions.each do |id|
      name = Institution.find(id).name
      @sorted_institutions[name] = id
    end
    @sorted_institutions = Hash[@sorted_institutions.sort]
    # Can be turned on if efficiency improves to the point where filter counts are plausible
    # counts = results.group(:institution_id).size
    # @inst_counts = {}
    # counts.each do |key, value|
    #   name = Institution.find(key).name
    #   @inst_counts[name] = [key, value]
    # end
    # @inst_counts = Hash[@inst_counts.sort]
  end

  def get_state_counts(results)
    @selected[:state] = params[:state] if params[:state] unless (params[:state].blank? || params[:state] == 'all' || params[:state] == 'All')
    @state_counts = results.group(:state).count
    @state_counts = Hash[@state_counts.sort]
  end

  def get_format_counts(results)
    @selected[:file_format] = params[:file_format] if params[:file_format]
    @format_counts = results.group(:file_format).count
    @format_counts = Hash[@format_counts.sort]
  end

  def get_object_format_counts(results)
    @selected[:file_format] = params[:file_format] if params[:file_format]
    @format_counts = results.joins(:generic_files).group(:file_format).count
    @format_counts = Hash[@format_counts.sort]
  end

  def get_object_access_counts(results)
    @selected[:access] = params[:access] if params[:access]
    @access_counts = results.group(:access).count
    @access_counts = Hash[@access_counts.sort]
  end

  def get_non_object_access_counts(results)
    @selected[:access] = params[:access] if params[:access]
    @access_counts = results.joins(:intellectual_object).group(:access).count
    @access_counts = Hash[@access_counts.sort]
  end

  def get_status_counts(results)
    @selected[:status] = params[:status] if params[:status]
    @status_counts = results.group(:status).count
    @status_counts['Null Status'] = @status_counts.delete(nil) if @status_counts[nil]
    @status_counts = Hash[@status_counts.sort]
  end

  def get_stage_counts(results)
    @selected[:stage] = params[:stage] if params[:stage]
    @stage_counts = results.group(:stage).count
    @stage_counts['Null Stage'] = @stage_counts.delete(nil) if @stage_counts[nil]
    @stage_counts = Hash[@stage_counts.sort]
  end

  def get_action_counts(results)
    @selected[:item_action] = params[:item_action] if params[:item_action]
    @action_counts = results.group(:action).count
    @action_counts = Hash[@action_counts.sort]
  end

  def get_retry_counts(results)
    @selected[:retry] = params[:retry] if params[:retry]
    @retry_counts = {}
    @retry_counts['t'] = results.with_retry('true').count
    @retry_counts['f'] = results.with_retry('false').count
  end

  def get_event_type_counts(results)
    @selected[:event_type] = params[:event_type] if params[:event_type]
    params[:event_type] ? @event_types = [params[:event_type]] : @event_types = Pharos::Application::PHAROS_EVENT_TYPES.values.sort
    # @event_type_counts = results.group(:event_type).size # Can be turned on if efficiency improves to the point where filter counts are plausible
  end

  def get_outcome_counts(results)
    @selected[:outcome] = params[:outcome] if params[:outcome]
    params[:outcome] ? @outcomes = [params[:outcome]] : @outcomes = %w(Failure Success)
    # @outcome_counts = results.group(:outcome).size # Can be turned on if efficiency improves to the point where filter counts are plausible
  end

  def get_node_counts(results)
    @selected[:remote_node] = params[:remote_node] if params[:remote_node]
    begin
      @node_counts = results.group(:remote_node).count
      @node_counts = Hash[@node_counts.sort]
    rescue Exception => ex
      logger.error ex.backtrace
    end
  end

  def get_queued_counts(results)
    if params[:queued] == 'is_queued'
      @selected[:queued] = 'Has been queued'
    elsif params[:queued] == 'is_not_queued'
      @selected[:queued] = 'Has not been queued'
    end
    @queued_filter = true
    @queued_counts = {}
    @queued_counts[:is_not_queued] = results.queued('is_not_queued').count
    @queued_counts[:is_queued] = results.queued('is_queued').count
  end

end
