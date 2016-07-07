class CatalogController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized

  def search
    authorize current_user
    params[:q] = '%' if params[:q] == '*'
    case params[:object_type]
      when 'object'
        object_search
      when 'file'
        file_search
      when 'item'
        item_search
      when '*'
        generic_search
    end
    filter
    page_and_authorize
    respond_to do |format|
      format.json { render json: {results: @results, next: @next, previous: @previous} }
      format.html { }
    end
  end

  protected

  def page_and_authorize
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    permission_check
    puts "results check: #{@results.count}, sample: #{@results.first}"
    @paged_results = @authorized_results.page(page).per(per_page)
    @next = format_next(page, per_page)
    @previous = format_previous(page, per_page)

  end

  def permission_check
    if current_user.admin?
      @authorized_results = @results
    else
      @authorized_results << @results.where(access: 'consortial')
      @authorized_results << @results.where(access: 'institution', institution_id: current_user.institution_id)
      @authorized_results << @results.where(access: 'restricted', institution_id: current_user.institution_id)
    end
  end

  def object_search
    @results = []
    case params[:search_field]
      when 'identifier'
        @results = IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'alt_identifier'
        @results = IntellectualObject.where('alternate_identifier LIKE ?', "%#{params[:q]}%")
      when 'bag_name'
        @results = IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
      when 'title'
        @results = IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
      when '*'
        @results << IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
        @results << IntellectualObject.where('alternate_identifier LIKE ?', "%#{params[:q]}%")
        @results << IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results << IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
    end
  end

  def file_search
    @results = []
    case params[:search_field]
      when 'identifier'
        @results = GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'uri'
        @results = GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
      when '*'
        @results << GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
        @results << GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
    end
  end

  def item_search
    @results = []
    case params[:search_field]
      when 'name'
        @results = WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'etag'
        @results = WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
      when 'object_identifier'
        @results = WorkItem.where('intellectual_object_identifier LIKE ?', "%#{params[:q]}%")
      when 'file_identifier'
        @results = WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
      when '*'
        @results << WorkItem.where('name LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('intellectual_object_identifier LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
    end
  end

  def generic_search
    @results = []
    case params[:search_field]
      when 'identifier'
        @results << IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
        @results << GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
      when 'alt_identifier'
        @results << IntellectualObject.where('alternate_identifier LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('intellectual_object_identifier LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
      when 'bag_name'
        @results << IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'title'
        @results = IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
      when 'uri'
        @results = GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
      when 'name'
        @results << IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('name LIKE ?', "%#{params[:q]}%")
      when 'etag'
        @results = WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
      when 'object_identifier'
        @results = WorkItem.where('intellectual_object_identifier LIKE ?', "%#{params[:q]}%")
      when 'file_identifier'
        @results = WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
      when '*'
        @results << IntellectualObject.where('identifier LIKE ?', "%#{params[:q]}%")
        @results << IntellectualObject.where('alternate_identifier LIKE ?', "%#{params[:q]}%")
        @results << IntellectualObject.where('bag_name LIKE ?', "%#{params[:q]}%")
        @results << IntellectualObject.where('title LIKE ?', "%#{params[:q]}%")
        @results << GenericFile.where('identifier LIKE ?', "%#{params[:q]}%")
        @results << GenericFile.where('uri LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('name LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('etag LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('intellectual_object_identifier LIKE ?', "%#{params[:q]}%")
        @results << WorkItem.where('generic_file_identifier LIKE ?', "%#{params[:q]}%")
    end
  end

  def filter
    set_filter_values
    filter_results
    set_page_counts
  end

  def set_filter_values
    @statuses = Pharos::Application::PHAROS_STATUSES.values
    @stages = Pharos::Application::PHAROS_STAGES.values
    @actions = Pharos::Application::PHAROS_ACTIONS.values
    @institutions = Array.new
    @accesses = %w(Consortial Institution Restricted)
    @formats = set_formats
    @associations = set_associations
    @types = ['Intellectual Objects', 'Generic Files', 'Work Items']
    Institution.all.each do |inst|
      @institutions.push(inst.identifier) unless inst.identifier == 'aptrust.org'
    end
    @counts = {}
    @selected = {}
  end

  def filter_results
    filter_by_status if params[:status].present?
    filter_by_stage if params[:stage].present?
    filter_by_action if params[:object_action].present?
    filter_by_institution if params[:institution].present?
    filter_by_access if params[:access].present?
    filter_by_format if params[:format].present?
    filter_by_association if params[:association].present?
    filter_by_type if params[:type].present?
  end

  def filter_by_status
    @results = @results.where(status: params[:status])
    @selected[:status] = params[:status]
    @statuses.each { |status| @counts[status] = @results.where(status: status).count() }
  end

  def filter_by_stage
    @results = @results.where(stage: params[:stage])
    @selected[:stage] = params[:stage]
    @stages.each { |stage| @counts[stage] = @results.where(stage: stage).count() }
  end

  def filter_by_action
    @results = @results.where(action: params[:object_action])
    @selected[:object_action] = params[:object_action]
    @actions.each { |action| @counts[action] = @results.where(action: action).count() }
  end

  def filter_by_institution
    @results = @results.where(institution: params[:institution])
    @selected[:institution] = params[:institution]
    @institutions.each { |institution| @counts[institution] = @results.where(institution: institution).count() }
  end

  def filter_by_access
    @results = @results.where(access: params[:access])
    @selected[:access] = params[:access]

    @accesses.each { |acc| @counts[acc] = @results.where(access: acc).count }
  end

  def filter_by_format
    #TODO: make sure this is applicable to objects as well as files
    @results = @results.where(format: params[:format])
    @selected[:format] = params[:format]
    @formats.each { |format| @counts[format] = @results.where(format: format).count }
  end

  def filter_by_association
    filtered_results = []
    filtered_results << @results.where(intellectual_object_id: params[:association])
    filtered_results << @results.where(generic_file_id: params[:association])
    @results = filtered_results
    @selected[:association] = params[:association]

    @associations.each { |assc| @counts[assc] = @results.where(intellectual_object: assc).count }
    @associations.each { |assc| @counts[assc] = @results.where(generic_file: assc).count }
  end

  def filter_by_type
    @results = @results.where(type: params[:type])
    @selected[:type] = params[:type]
    @types.each { |type| @counts[type] = @results.where(type: type).count }
  end

  def set_page_counts
    @count = @results.count
    if @count == 0
      @second_number = 0
      @first_number = 0
    elsif params[:page].nil?
      @second_number = 10
      @first_number = 1
    else
      @second_number = params[:page].to_i * 10
      @first_number = @second_number.to_i - 9
    end
    @second_number = @count if @second_number > @count
  end

  def set_formats
    #TODO: figure out how to set these without looping through all objects
    Array.new
  end

  def set_associations
    #TODO: figure out how to set these without looping through all objects
    Array.new
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def to_boolean(str)
    str == 'true'
  end

  def format_next(page, per_page)
    if @count.to_f / per_page <= page
      nil
    else
      new_page = page + 1
      new_url = "#{request.base_url}/search/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous(page, per_page)
    if page == 1
      nil
    else
      new_page = page - 1
      new_url = "#{request.base_url}/search/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&q=#{params[:q]}" if params[:q].present?
    str = str << "&search_field=#{params[:search_field]}" if params[:search_field].present?
    str = str << "&object_type=#{params[:object_type]}" if params[:object_type].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&object_action=#{params[:object_action]}" if params[:object_action].present?
    str = str << "&stage=#{params[:stage]}" if params[:stage].present?
    str = str << "&status=#{params[:status]}" if params[:status].present?
    str = str << "&access=#{params[:access]}" if params[:access].present?
    str = str << "&format=#{params[:format]}" if params[:format].present?
    str = str << "&association=#{params[:association]}" if params[:association].present?
    str = str << "&type=#{params[:type]}" if params[:type].present?
    str
  end

end