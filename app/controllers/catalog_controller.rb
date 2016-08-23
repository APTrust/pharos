class CatalogController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
  after_action :verify_authorized

  def search
    params[:q] = '%' if params[:q] == '*'
    params[:q] = '%' if params[:q].nil?
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
      when 'All Types'
        generic_search
      when 'Premis Events'
        event_search
      when '*'
        generic_search
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

  protected

  def merge_results
    @merged_results = []
    @results.each { |key, value| @merged_results += value }
  end

  def object_search
    # Limit results to those the current user is allowed to read.
    objects = IntellectualObject.discoverable(current_user)
    case params[:search_field]
      when 'Intellectual Object Identifier'
        @results[:objects] = objects.with_identifier_like(params[:q])
      when 'Alternate Identifier'
        @results[:objects] = objects.with_alt_identifier_like(params[:q])
      when 'Bag Name'
        @results[:objects] = objects.with_bag_name_like(params[:q])
      when 'Title'
        @results[:objects] = objects.with_title_like(params[:q])
      when 'All Fields'
        @results[:objects] = objects.where('intellectual_objects.identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                           "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def file_search
    # Limit results to those the current user is allowed to read.
    files = GenericFile.discoverable(current_user)
    case params[:search_field]
      when 'Generic File Identifier'
        @results[:files] = files.with_identifier_like(params[:q])
      when 'URI'
        @results[:files] = files.with_uri_like(params[:q])
      when 'All Fields'
        @results[:files] = files.where('generic_files.identifier LIKE ? OR generic_files.uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def item_search
    # Limit results to those the current user is allowed to read.
    items = WorkItem.readable(current_user)
    case params[:search_field]
      when 'Name'
        @results[:items] = items.with_name_like(params[:q])
      when 'Etag'
        @results[:items] = items.with_etag_like(params[:q])
      when 'Intellectual Object Identifier'
        @results[:items] = items.with_object_identifier_like(params[:q])
      when 'Generic File Identifier'
        @results[:items] = items.with_file_identifier_like(params[:q])
      when 'All Fields'
        @results[:items] = items.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                       "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def event_search
    #TODO: find way to add generic file identifier to all fields search without compound joins which precludes events only attached to objects
    events = PremisEvent.discoverable(current_user)
    case params[:search_field]
      when 'Event Identifier'
        @results[:events] = events.with_event_identifier_like(params[:q])
      when 'Intellectual Object Identifier'
        @results[:events] = events.with_object_identifier_like(params[:q])
      when 'Generic File Identifier'
        @results[:events] = events.with_file_identifier_like(params[:q])
      when 'All Fields'
        @results[:events] = events.joins(:intellectual_object).where('premis_events.identifier LIKE ? OR
                                          intellectual_objects.identifier LIKE ?',
                                          "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def generic_search
    objects = IntellectualObject.discoverable(current_user)
    files = GenericFile.discoverable(current_user)
    items = WorkItem.readable(current_user)
    events = PremisEvent.discoverable(current_user)
    case params[:search_field]
      when 'Alternate Identifier'
        @results[:objects] = objects.with_alt_identifier_like(params[:q])
        @results[:items] = items.where('object_identifier LIKE ? OR generic_file_identifier LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
      when 'Bag Name'
        @results[:objects] = objects.with_bag_name_like(params[:q])
        @results[:items] = items.with_name_like(params[:q])
      when 'Title'
        @results[:objects] = objects.with_title_like(params[:q])
      when 'URI'
        @results[:files] = files.with_uri_like(params[:q])
      when 'Name'
        @results[:objects] = objects.with_bag_name_like(params[:q])
        @results[:items] = items.with_name_like(params[:q])
      when 'Etag'
        @results[:items] = items.with_etag_like(params[:q])
      when 'Intellectual Object Identifier'
        @results[:items] = items.with_object_identifier_like(params[:q])
        @results[:objects] = objects.with_identifier_like(params[:q])
        @results[:events] = events.with_object_identifier_like(params[:q])
      when 'Generic File Identifier'
        @results[:items] = items.with_file_identifier_like(params[:q])
        @results[:files] = files.with_identifier_like(params[:q])
        @results[:events] = events.with_file_identifier_like(params[:q])
      when 'Event Identifier'
        @results[:events] = events.with_event_identifier_like(params[:q])
      when 'All Fields'
        @results[:objects] = objects.where('intellectual_objects.identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                          "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:files] = files.where('generic_files.identifier LIKE ? OR uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:items] = items.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                          "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:events] = events.joins(:intellectual_object).joins(:generic_file).where('premis_events.identifier LIKE ? OR
                                          intellectual_objects.identifier LIKE ? OR generic_files.identifier LIKE ?',
                                          "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def filter
    set_filter_values
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
    # gf_object_associations = @results[:files].distinct.pluck(:intellectual_object_id) unless @results[:files].nil?
    # wi_object_associations = @results[:items].distinct.pluck(:intellectual_object_id) unless @results[:items].nil?
    # event_object_associations = @results[:events].distinct.pluck(:intellectual_object_id) unless @results[:events].nil?
    # @object_associations = gf_object_associations | wi_object_associations | event_object_associations
    # wi_file_associations = @results[:items].distinct.pluck(:generic_file_id) unless @results[:items].nil?
    # event_file_associations = @results[:events].distinct.pluck(:generic_file_id) unless @results[:events].nil?
    # @file_associations = wi_file_associations | event_file_associations
    @types = ['Intellectual Objects', 'Generic Files', 'Work Items', 'Premis Events']
    @event_types = @results[:events].distinct.pluck(:event_type) unless @results[:events].nil?
    @outcomes = @results[:events].distinct.pluck(:outcome) unless @results[:events].nil?
  end

  def set_filter_counts
    @results.each do |key, results|
      if key == :objects
        set_inst_count(results)
        set_access_count(results)
        set_format_count(results)
      elsif key == :files
        set_format_count(results)
        set_inst_count(results)
        #set_io_assc_count(results)
        #set_access_count(results)
      elsif key == :items
        set_status_count(results)
        set_stage_count(results)
        set_action_count(results)
        set_inst_count(results)
        set_access_count(results)
        #set_io_assc_count(results)
        #set_gf_assc_count(results)
      elsif key == :events
        set_inst_count(results)
        set_access_count(results)
        #set_io_assc_count(results)
        #set_gf_assc_count(results)
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
