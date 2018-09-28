class CatalogController < ApplicationController
  include FilterCounts
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
    filter_sort_and_count
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
    objects = IntellectualObject.discoverable(current_user)
    @result_type = 'object'
    if @empty_param
      @results = objects
    else
      case params[:search_field]
        when 'Object Identifier'
          @results = objects.with_identifier(@q)
          @results = objects.with_identifier_like(@q) if @results.count == 0
        when 'Alternate Identifier'
          @results = objects.with_alt_identifier_like(@q)
        when 'Bag Name'
          @results = objects.with_bag_name_like(@q)
        when 'Title'
          @results = objects.with_title_like(@q)
        when 'Bag Group Identifier'
          @results = objects.with_bag_group_identifier_like(@q)
      end
    end
  end

  def file_search
    files = GenericFile.discoverable(current_user)
    @result_type = 'file'
    if @empty_param
      @results = files
    else
      case params[:search_field]
        when 'File Identifier'
          @results = files.with_identifier(@q)
          @results = files.with_identifier_like(@q) if @results.count == 0
        when 'URI'
          @results = files.with_uri_like(@q)
      end
    end
  end

  def item_search
    items = WorkItem.readable(current_user)
    @result_type = 'item'
    if @empty_param
      @results = items
    else
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
  end

  def event_search
    events = PremisEvent.discoverable(current_user)
    @result_type = 'event'
    if @empty_param
      @results = events
    else
      case params[:search_field]
        when 'Event Identifier'
          @results = events.with_event_identifier(@q)
        when 'Object Identifier'
          @results = events.with_object_identifier(@q)
        when 'File Identifier'
          @results = events.with_file_identifier(@q)
      end
    end
  end

  def dpn_item_search
    items = DpnWorkItem.discoverable(current_user)
    @result_type = 'dpn_item'
    if @empty_param
      @results = items
    else
      case params[:search_field]
        when 'Item Identifier'
          @results = items.with_identifier(@q)
      end
    end
  end

  def filter_sort_and_count
    @selected = {}
    params[:state] = 'A' if params[:state].nil?
    case @result_type
      when 'object'
        @results = @results
                       .with_institution(params[:institution])
                       .with_access(params[:access])
                       .with_state(params[:state])
        get_institution_counts(@results)
        get_object_access_counts(@results)
        get_state_counts(@results)
      when 'file'
        @results = @results
                       .with_institution(params[:institution])
                       .with_access(params[:access])
                       .with_file_format(params[:file_format])
                       .with_state(params[:state])
        get_institution_counts(@results)
        get_format_counts(@results)
        get_non_object_access_counts(@results)
        get_state_counts(@results)
      when 'item'
        @results = @results
                       .with_institution(params[:institution])
                       .with_status(params[:status])
                       .with_stage(params[:stage])
                       .with_action(params[:item_action])
                       .with_access(params[:access])
        get_status_counts(@results)
        get_stage_counts(@results)
        get_action_counts(@results)
        get_institution_counts(@results)
        get_non_object_access_counts(@results)
      when 'event'
        @results = @results
                       .with_institution(params[:institution])
                       .with_type(params[:event_type])
                       .with_outcome(params[:outcome])
                       .with_access(params[:access])
        get_event_institution_counts(@results)
        get_event_type_counts(@results)
        get_outcome_counts(@results)
      when 'dpn_item'
        params[:status] = nil if params[:status] == 'Null Status'
        params[:stage] = nil if params[:stage] == 'Null Stage'
        @results = @results
                       .with_remote_node(params[:remote_node])
                       .queued(params[:queued])
                       .with_stage(params[:stage])
                       .with_status(params[:status])
                       .with_retry(params[:retry])
        get_node_counts(@results)
        get_queued_counts(@results)
        get_status_counts(@results)
        get_stage_counts(@results)
        get_retry_counts(@results)
    end
    params[:sort] = 'date' unless params[:sort]
    case params[:sort]
      when 'date'
        sort_by_date
      when 'name'
        sort_by_name
      when 'institution'
        sort_by_institution
    end
    count = @results.count
    set_page_counts(count)
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

end
