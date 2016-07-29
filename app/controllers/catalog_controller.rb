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
        object_search
        file_search
        item_search
      when '*'
        object_search
        file_search
        item_search
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
    merge_results
    @paged_results = Kaminari.paginate_array(@authorized_results).page(@page).per(@per_page)
    @next = format_next
    @current = format_current
    @previous = format_previous
  end

  def merge_results
    @authorized_results = []
    @results.each { |key, value| @authorized_results += value }
    @authorized_results
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

  # def generic_search
  #   case params[:search_field]
  #     when 'Identifier'
  #       @results[:objects] = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
  #       @results[:files] = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
  #     when 'Alternate Identifier'
  #       @results[:objects] = IntellectualObject.where('alt_identifier LIKE ?', "%#{params[:q]}%")
  #       @results[:items] = WorkItem.where('object_identifier LIKE ? OR generic_file_identifier LIKE ?',
  #                                     "%#{params[:q]}%", "%#{params[:q]}%")
  #     when 'Bag Name'
  #       @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
  #       @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
  #     when 'Title'
  #       @results[:objects] = IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
  #     when 'URI'
  #       @results[:files] = GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
  #     when 'Name'
  #       @results[:objects] = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
  #       @results[:items] = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
  #     when 'Etag'
  #       @results[:items] = WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
  #     when 'Intellectual Object Identifier'
  #       @results[:items] = WorkItem.where('object_identifier LIKE ?', "%#{params[:q]}%")
  #       @results[:objects] = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
  #     when 'Generic File Identifier'
  #       @results[:items] = WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
  #       @results[:files] = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
  #     when 'All Fields'
  #       @results[:objects] = IntellectualObject.where('identifier LIKE ? OR alt_identifier LIKE ? OR bag_name LIKE ? OR title LIKE ?',
  #                                             "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
  #       @results[:files] = GenericFile.where('identifier LIKE ? OR uri LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
  #       @results[:items] = WorkItem.where('name LIKE ? OR etag LIKE ? OR object_identifier LIKE ? OR generic_file_identifier LIKE ?',
  #                                     "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
  #   end
  #   # Limit results to those the current user is allowed to read.
  #   @results[:files].readable(current_user) unless @results[:files].nil?
  #   @results[:items].readable(current_user) unless @results[:items].nil?
  #   @results[:objects].readable(current_user) unless @results[:objects].nil?
  # end

  def filter
    set_filter_values
    filter_results
    set_filter_counts
    set_page_counts
  end

  def set_filter_values
    @statuses = Pharos::Application::PHAROS_STATUSES.values
    @stages = Pharos::Application::PHAROS_STAGES.values
    @actions = Pharos::Application::PHAROS_ACTIONS.values
    @institutions = Institution.pluck(:id)
    @accesses = %w(Consortial Institution Restricted)
    @formats = GenericFile.distinct.pluck(:file_format)
    # TODO: Don't call distinct on the GenericFile table,
    # because that will scan millions of records and pull
    # back tens of thousands of intel_obj_ids. What is
    # this stat for?
    file_associations = GenericFile.distinct.pluck(:intellectual_object_id)
    item_io_associations = WorkItem.distinct.pluck(:intellectual_object_id)
    item_gf_associations = WorkItem.distinct.pluck(:generic_file_id)
    deduped_io_associations = file_associations | item_io_associations
    @associations = deduped_io_associations + item_gf_associations
    @counts = {}
    @selected = {}
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
    @selected[:status] = params[:status]
  end

  def filter_by_stage
    @results[:items] = @results[:items].where(stage: params[:stage]) unless @results[:items].nil?
    @selected[:stage] = params[:stage]
  end

  def filter_by_action
    @results[:items] = @results[:items].where(action: params[:object_action]) unless @results[:items].nil?
    @selected[:object_action] = params[:object_action]
  end

  def filter_by_institution
    @results[:objects] = @results[:objects].where(institution_id: params[:institution]) unless @results[:objects].nil?
    @results[:files] = @results[:files].joins(:intellectual_object).where(intellectual_objects: { institution_id: params[:institution] }) unless @results[:files].nil?
    @results[:items] = @results[:items].where(institution_id: params[:institution]) unless @results[:items].nil?
    @selected[:institution] = params[:institution]
  end

  def filter_by_access
    @results[:objects] = @results[:objects].where(access: params[:access]) unless @results[:objects].nil?
    @results[:files] = @results[:files].joins(:intellectual_object).where(intellectual_objects: { access: params[:access] }) unless @results[:files].nil?
    @results[:items] = @results[:items].joins(:intellectual_object).where(intellectual_objects: { access: params[:access] }) unless @results[:items].nil?
    @selected[:access] = params[:access]
  end

  def filter_by_format
    #TODO: make sure this is applicable to objects as well as files
    @results[:files] = @results[:files].where(file_format: params[:file_format]) unless @results[:files].nil?
    #@results[:objects] = @results[:objects].where(file_format: params[:file_format]) unless @results[:objects].nil?
    @selected[:file_format] = params[:file_format]
  end

  def filter_by_association
    @results[:items] = @results[:items].where('intellectual_object_id LIKE ? OR generic_file_id LIKE ?',
                                              params[:association], params[:association]) unless @results[:items].nil?
    @results[:files] = @results[:files].where(intellectual_object_id: params[:association]) unless @results[:files].nil?
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
    unless params[:state] == 'all'
      @results[:objects] = @results[:objects].where(state: params[:state]) unless @results[:objects].nil?
      @results[:files] = @results[:files].where(state: params[:state]) unless @results[:files].nil?
      @results[:items] = @results[:items].where(state: params[:state]) unless @results[:items].nil?
      @selected[:state] = params[:state]
    end
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
    @results.each do |key, value|
      if key == 'objects'
        @institutions.each { |institution| @counts[:inst][institution] += value.where(institution_id: institution).count }
        @accesses.each { |acc| @counts[:access][acc] += value.where(access: acc).count }
        @formats.each { |format| @counts[:formats][format] += value.where(file_format: format).count }
      elsif key == 'files'
        @formats.each { |format| @counts[:formats][format] += value.where(file_format: format).count }
        @institutions.each { |institution| @counts[:inst][institution] += value.joins(:intellectual_object).where(intellectual_objects: { institution_id: institution.id }).count }
        @associations.each { |assc| @counts[:related][assc] += value.where(intellectual_object_id: assc).count }
        @accesses.each { |acc| @counts[:access][acc] += value.joins(:intellectual_object).where(intellectual_objects: { access: acc }).count }
      elsif key == 'items'
        @statuses.each { |status| @counts[:status][status] += value.where(status: status).count }
        @stages.each { |stage| @counts[:stage][stage] += value.where(stage: stage).count }
        @actions.each { |action| @counts[:action][action] += value.where(action: action).count }
        @institutions.each { |institution| @counts[:inst][institution] += value.joins(:intellectual_object).where(intellectual_objects: { institution_id: institution.id }).count }
        @accesses.each { |acc| @counts[:access][acc] += value.joins(:intellectual_object).where(intellectual_objects: { access: acc }).count }
        @associations.each { |assc| @counts[:related][assc] += value.where(intellectual_object_id: assc).count }
        @associations.each { |assc| @counts[:related][assc] += value.where(generic_file_id: assc).count }
      end
    end
    @counts[:type] = {}
    @counts[:type]['Intellectual Objects'] = @results[:objects].count unless @results[:objects].nil?
    @counts[:type]['Generic Files'] = @results[:files].count unless @results[:files].nil?
    @counts[:type]['Work Items'] = @results[:items].count unless @results[:items].nil?
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
