class CatalogController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
  after_action :verify_authorized

  def search
    if params[:q] == '*' || params[:q].nil? || params[:q] == ''
      @q = '%'
      @empty_param = true
    else
      @q = params[:q]
      @empty_param = false
    end
    @results = {}
    authorize current_user
    generic_search if params[:object_type].nil?
    case params[:object_type]
      when 'Intellectual Objects'
        object_search
      when 'Generic Files'
        file_search
      when 'Work Items'
        item_search
      when 'Premis Events'
        event_search
    end
    filter
    sort
    merge_results
    page_results(@merged_results)
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

  # Merge all objects, files, events and work items into a single flat array.
  # Be sure to paginate this first, or it will load millions of objects into
  # memory and crash the server.
  def merge_results
    @merged_results = []
    @results.each { |key, value| @merged_results += value.limit(params[:per_page].to_i) }
  end

  def object_search
    # Limit results to those the current user is allowed to read.
    objects = IntellectualObject.discoverable(current_user)
    if @empty_param
      @results[:objects] = objects
      return
    end
    case params[:search_field]
      when 'Object Identifier'
        @results[:objects] = objects.with_identifier(@q)
      when 'Alternate Identifier'
        @results[:objects] = objects.with_alt_identifier_like(@q)
      when 'Bag Name'
        @results[:objects] = objects.with_bag_name_like(@q)
      when 'Title'
        @results[:objects] = objects.with_title_like(@q)
      when 'All Fields'
        @results[:objects] = objects.where('intellectual_objects.identifier = ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                           "%#{@q}%", "%#{@q}%", "%#{@q}%", "%#{@q}%")
    end
  end

  def file_search
    # Limit results to those the current user is allowed to read.
    files = GenericFile.discoverable(current_user)
    if @empty_param
      @results[:files] = files
      return
    end
    case params[:search_field]
      when 'File Identifier'
        @results[:files] = files.with_identifier(@q)
      when 'URI'
        @results[:files] = files.with_uri_like(@q)
      when 'All Fields'
        @results[:files] = files.where('generic_files.identifier = ? OR generic_files.uri LIKE ?', "%#{@q}%", "%#{@q}%")
    end
  end

  def item_search
    # Limit results to those the current user is allowed to read.
    items = WorkItem.readable(current_user)
    if @empty_param
      @results[:items] = items
      return
    end
    case params[:search_field]
      when 'Name'
        @results[:items] = items.with_name_like(@q)
      when 'Etag'
        @results[:items] = items.with_etag_like(@q)
      when 'Object Identifier'
        @results[:items] = items.with_object_identifier(@q)
      when 'File Identifier'
        @results[:items] = items.with_file_identifier(@q)
      when 'All Fields'
        @results[:items] = items.where('name LIKE ? OR work_items.etag LIKE ? OR object_identifier = ? OR generic_file_identifier = ?',
                                       "%#{@q}%", "%#{@q}%", "%#{@q}%", "%#{@q}%")
    end
  end

  def event_search
    events = PremisEvent.discoverable(current_user)
    if @empty_param
      @results[:events] = events
      return
    end
    case params[:search_field]
      when 'Event Identifier'
        @results[:events] = events.with_event_identifier(@q)
      when 'Object Identifier'
        @results[:events] = events.with_object_identifier(@q)
      when 'File Identifier'
        @results[:events] = events.with_file_identifier(@q)
      # when 'All Fields'
      #   @results[:events] = events.where('premis_events.identifier = ? OR intellectual_object_identifier = ?
      #                                     OR generic_file_identifier = ?', "%#{@q}%", "%#{@q}%", "%#{@q}%")
    end
  end

  def filter
    initialize_filter_counters
    filter_by_status unless params[:status].nil?
    filter_by_stage unless params[:stage].nil?
    filter_by_action unless params[:item_action].nil?
    filter_by_institution unless params[:institution].nil?
    filter_by_access unless params[:access].nil?
    filter_by_object_association unless params[:object_association].nil?
    filter_by_file_association unless params[:file_association].nil?
    filter_by_type unless params[:type].nil?
    filter_by_state unless params[:state].nil?
    filter_by_format unless params[:file_format].nil?
    filter_by_event_type unless params[:event_type].nil?
    filter_by_outcome unless params[:outcome].nil?
    set_filter_values
    set_filter_counts
    count = 0
    @results.each { |key, value| count = count + value.count }
    set_page_counts(count)
  end

  def set_filter_values
    @statuses = @results[:items].distinct.pluck(:status) unless @results[:items].nil?
    @stages = @results[:items].distinct.pluck(:stage) unless @results[:items].nil?
    @actions = @results[:items].distinct.pluck(:action) unless @results[:items].nil?
    @institutions = Institution.pluck(:id)
    @accesses = %w(consortia institution restricted)
    @formats = @results[:files].distinct.pluck(:file_format) unless @results[:files].nil?
    @types = ['Intellectual Objects', 'Generic Files', 'Work Items', 'Premis Events']
    @event_types = @results[:events].distinct.pluck(:event_type) unless @results[:events].nil?
    @outcomes = @results[:events].distinct.pluck(:outcome) unless @results[:events].nil?
  end

  def set_filter_counts
    @results.each do |key, results|
      if key == :objects
        set_inst_count(results, key)
        set_access_count(results)
      elsif key == :files
        set_format_count(results, key)
        set_inst_count(results, key)
        set_access_count(results)
      elsif key == :items
        set_status_count(results)
        set_stage_count(results)
        set_action_count(results)
        set_inst_count(results, key)
        set_access_count(results)
      elsif key == :events
        set_inst_count(results, key)
        set_access_count(results)
        set_event_type_count(results)
        set_outcome_count(results)
      end
    end
    @type_counts['Intellectual Objects'] = @results[:objects].count unless @results[:objects].nil?
    @type_counts['Generic Files'] = @results[:files].count unless @results[:files].nil?
    @type_counts['Work Items'] = @results[:items].count unless @results[:items].nil?
    @type_counts['Premis Events'] = @results[:events].count unless @results[:events].nil?
  end

end
