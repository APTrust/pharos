class CatalogController < ApplicationController
  include SearchAndIndex
  before_action :authenticate_user!
  after_action :verify_authorized

  def search
    if params[:q] == '*' || params[:q].nil? || params[:q] == ''
      @q = '%'
      @empty_param = true
    else
      @q = params[:q]
      @empty_param = false
    end
    @q = @q.strip
    @results = []
    authorize current_user
    case params[:object_type]
      when 'Intellectual Objects'
        object_search
      when 'Generic Files'
        file_search
      when 'Work Items'
        item_search
      when 'Premis Events'
        event_search
      when 'DPN Items'
        dpn_item_search
    end
    filter
    params[:sort] = 'date' unless params[:sort]
    sort
    page_results(@results)
    respond_to do |format|
      format.json { render json: {results: @paged_results, next: @next, previous: @previous} }
      format.html { }
    end
  end

  def feed
    authorize current_user
    current_user.admin? ?
        @rss_items = WorkItem.order('date').reverse_order :
        @rss_items = WorkItem.with_institution(current_user.institution_id).order('date').reverse_order
    respond_to do |format|
      format.rss { render :layout => false }
    end
  end

  protected

  def object_search
    # Limit results to those the current user is allowed to read.
    objects = IntellectualObject.discoverable(current_user)
    @result_type = 'object'
    if @empty_param
      @results = objects
      return
    end
    case params[:search_field]
      when 'Object Identifier'
        @results = objects.with_identifier(@q)
      when 'Alternate Identifier'
        @results = objects.with_alt_identifier_like(@q)
      when 'Bag Name'
        @results = objects.with_bag_name_like(@q)
      when 'Title'
        @results = objects.with_title_like(@q)
    end
  end

  def file_search
    # Limit results to those the current user is allowed to read.
    files = GenericFile.discoverable(current_user)
    @result_type = 'file'
    if @empty_param
      @results = files
      return
    end
    case params[:search_field]
      when 'File Identifier'
        @results = files.with_identifier(@q)
      when 'URI'
        @results = files.with_uri_like(@q)
    end
  end

  def item_search
    # Limit results to those the current user is allowed to read.
    items = WorkItem.readable(current_user)
    @result_type = 'item'
    if @empty_param
      @results = items
      return
    end
    case params[:search_field]
      when 'Name'
        @results = items.with_name_like(@q)
      when 'Etag'
        @results = items.with_etag_like(@q)
      when 'Object Identifier'
        @results = items.with_object_identifier(@q)
      when 'File Identifier'
        @results = items.with_file_identifier(@q)
    end
  end

  def event_search
    events = PremisEvent.discoverable(current_user)
    @result_type = 'event'
    if @empty_param
      @results = events
      return
    end
    case params[:search_field]
      when 'Event Identifier'
        @results = events.with_event_identifier(@q)
      when 'Object Identifier'
        @results = events.with_object_identifier(@q)
      when 'File Identifier'
        @results = events.with_file_identifier(@q)
    end
  end

  def dpn_item_search
    items = DpnWorkItem.discoverable(current_user)
    @result_type = 'dpn_item'
    if @empty_param
      @results = items
      return
    end
    case params[:search_field]
      when 'Item Identifier'
        @results = items.with_identifier(@q)
    end
  end

  def filter
    initialize_filter_counters
    filter_by_status unless params[:status].nil?
    filter_by_stage unless params[:stage].nil?
    filter_by_action unless params[:item_action].nil?
    filter_by_institution unless params[:institution].nil?
    filter_by_access unless params[:access].nil?
    filter_by_state unless params[:state].nil?
    filter_by_format unless params[:file_format].nil?
    filter_by_event_type unless params[:event_type].nil?
    filter_by_outcome unless params[:outcome].nil?
    filter_by_node unless params[:remote_node].nil?
    filter_by_queued unless params[:queued].nil?
    set_filter_values
    set_filter_counts
    count = @results.count
    set_page_counts(count)
  end

  def set_filter_values
    case @result_type
      when 'object'
        params[:institution] ? @institutions = [params[:institution]] : @institutions = Institution.pluck(:id) # This will definitely lead to institutions with no results listed in the filters w/o counts
        params[:access] ? @accesses = [params[:access]] : @accesses = %w(consortia institution restricted) # As will this
      when 'file'
        params[:institution] ? @institutions = [params[:institution]] : @institutions = Institution.pluck(:id)
        params[:file_format] ? @formats = [params[:file_format]] : @formats = @results.distinct.pluck(:file_format)
      when 'item'
        params[:institution] ? @institutions = [params[:institution]] : @institutions = Institution.pluck(:id)
        params[:status] ? @statuses = [params[:status]] : @statuses = Pharos::Application::PHAROS_STATUSES.values
        params[:stage] ? @stages = [params[:stage]] : @stages = Pharos::Application::PHAROS_STAGES.values
        params[:item_action] ? @actions = [params[:item_action]] : @actions = Pharos::Application::PHAROS_ACTIONS.values
      when 'event'
        params[:institution] ? @institutions = [params[:institution]] : @institutions = Institution.pluck(:id)
        params[:event_type] ? @event_types = [params[:event_type]] : @event_types = Pharos::Application::PHAROS_EVENT_TYPES.values
        params[:outcome] ? @outcomes = [params[:outcome]] : @outcomes = %w(Success Failure)
      when 'dpn_item'
        params[:remote_node] ? @nodes = [params[:remote_node]] : @nodes = %w(chron hathi sdr tdr aptrust)
        @queued_filter = true
    end
  end

  def set_filter_counts
    case @result_type
      when 'object'
        set_inst_count(@results, :objects)
        set_access_count(@results)
      when 'file'
        set_format_count(@results, :files)
        set_inst_count(@results, :files)
      when 'item'
        set_status_count(@results)
        set_stage_count(@results)
        set_action_count(@results)
        set_inst_count(@results, :items)
      when 'event'
        #set_inst_count(@results, :events)
        #set_event_type_count(@results)
        #set_outcome_count(@results)
      when 'dpn_item'
        set_node_count(@results)
        set_queued_count(@results)
    end
  end

end
