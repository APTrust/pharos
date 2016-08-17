class CatalogController < ApplicationController
  include SearchAndIndex
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
      when 'Identifier'
        @results[:objects] = objects.with_identifier_like(params[:q])
      when 'Intellectual Object Identifier'
        @results[:objects] = objects.with_identifier_like(params[:q])
      when 'Alternate Identifier'
        @results[:objects] = objects.with_alt_identifier_like(params[:q])
      when 'Bag Name'
        @results[:objects] = objects.with_bag_name_like(params[:q])
      when 'Title'
        @results[:objects] = objects.with_title_like(params[:q])
      when 'All Fields'
        @results[:objects] = objects.where('identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                           "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def file_search
    # Limit results to those the current user is allowed to read.
    files = GenericFile.discoverable(current_user)
    case params[:search_field]
      when 'Identifier'
        @results[:files] = files.with_identifier_like(params[:q])
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

  def generic_search
    objects = IntellectualObject.discoverable(current_user)
    files = GenericFile.discoverable(current_user)
    items = WorkItem.readable(current_user)
    case params[:search_field]
      when 'Identifier'
        @results[:objects] = objects.with_identifier_like(params[:q])
        @results[:files] = files.with_identifier_like(params[:q])
      when 'Alternate Identifier'
        @results[:objects] = objects.with_alt_identifier_like(params[:q])
        io_items = items.with_object_identifier_like(params[:q])
        gf_items = items.with_file_identifier_like(params[:q])
        @results[:items] = io_items | gf_items
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
      when 'Generic File Identifier'
        @results[:items] = items.with_file_identifier_like(params[:q])
        @results[:files] = files.with_identifier_like(params[:q])
      when 'All Fields'
        @results[:objects] = objects.where('identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
                                              "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:files] = files.where('generic_files.identifier LIKE ? OR uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
        @results[:items] = items.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
                                      "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
  end

  def filter
    set_filter_values
    filter_by_status unless params[:status].nil?
    filter_by_stage unless params[:stage].nil?
    filter_by_action unless params[:item_action].nil?
    filter_by_institution unless params[:institution].nil?
    filter_by_access unless params[:access].nil?
    filter_by_association unless params[:association].nil?
    filter_by_type unless params[:type].nil?
    filter_by_state unless params[:state].nil?
    filter_by_format unless params[:file_format].nil?
    set_filter_counts
    count = 0
    @results.each { |key, value| count = count + value.count }
    set_page_counts(count)
  end

  def set_filter_counts
    @counts = {}
    # @results.each do |key, results|
    #   if key == :objects
    #     set_inst_count(results)
    #     set_access_count(results)
    #     #set_format_count(results)
    #   elsif key == :files
    #     set_format_count(results)
    #     set_inst_count(results)
    #     set_io_assc_count(results)
    #     set_access_count(results)
    #   elsif key == :items
    #     set_status_count(results)
    #     set_stage_count(results)
    #     set_action_count(results)
    #     set_inst_count(results)
    #     set_access_count(results)
    #     set_io_assc_count(results)
    #     set_gf_assc_count(results)
    #   end
    # end
    @counts['Intellectual Objects'] = @results[:objects].count unless @results[:objects].nil?
    @counts['Generic Files'] = @results[:files].count unless @results[:files].nil?
    @counts['Work Items'] = @results[:items].count unless @results[:items].nil?
  end

end
