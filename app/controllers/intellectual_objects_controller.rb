class IntellectualObjectsController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  before_action :load_institution, only: [:index, :create]
  before_action :load_object, only: [:show, :edit, :update, :destroy]

  def index
    authorize @institution
    if params[:search_field].present?
      filter_results_by_standard_params
      prep_search_incidentals
    elsif params[:alt_action].present?
      @intellectual_object = IntellectualObject.where(identifier: params[:q]).first
    else
      narrow_results_to_specific_institution
      filter_results_by_other_params
      prep_search_incidentals
    end
    respond_to do |format|
      format.json { render json: {count: @count, next: @next, previous: @previous, results: @intellectual_objects.map{ |item| item.serializable_hash(include: [:etag])}} }
      format.html {
        if params[:alt_action].present?
          case params[:alt_action]
            when 'dpn'
              send_to_dpn
            when 'restore'
              restore_item
          end
        else
          index!
        end
      }
    end
  end

  def create
    authorize @institution, :create_through_institution?
    @intellectual_object = @institution.intellectual_objects.new(intellectual_object_params)
    create!
    respond_to do |format|
      format.json { render object_as_json }
      format.html { }
    end
  end

  def show
    authorize @intellectual_object
    if @intellectual_object.nil? || @intellectual_object.state == 'D'
      respond_to do |format|
        format.json { render :nothing => true, :status => 404 }
        format.html
      end
    else
      respond_to do |format|
        format.json { render json: object_as_json }
        format.html
      end
    end
  end

  def edit
    authorize @intellectual_object
    edit!
  end

  def update
    authorize @intellectual_object
    respond_to(:html, :json)
    update!
  end

  def destroy
    authorize @intellectual_object, :soft_delete?
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has already been deleted.'
    elsif pending == 'false'
      attributes = { event_type: 'delete',
                     date_time: "#{Time.now}",
                     detail: 'Object deleted from S3 storage',
                     outcome: 'Success',
                     outcome_detail: current_user.email,
                     object: 'Goamz S3 Client',
                     agent: 'https://github.com/crowdmob/goamz',
                     outcome_information: "Action requested by user from #{current_user.institution_id}",
                     identifier: SecureRandom.uuid
      }
      resource.soft_delete(attributes)
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been queued for object: #{resource.title}. Depending on the size of the object, it may take a few minutes for all associated files to be marked as deleted."
          redirect_to root_path
        }
      end
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be deleted at this time due to a pending #{pending} request."
    end
  end

  # def create_from_json
  #   # new_object is the IntellectualObject we're creating.
  #   # current_object is the item we're about to save at any
  #   # given step of this operation. We use this in the rescue
  #   # clause to let the caller know where the operation failed.
  #   state = {
  #       current_object: nil,
  #       object_events: [],
  #       object_files: [],
  #   }
  #   if params[:include_nested] == 'true'
  #     begin
  #       json_param = get_create_params
  #       object = JSON.parse(json_param.to_json).first
  #       # We might be re-ingesting a previously-deleted intellectual object,
  #       # or more likely, creating a new intel obj. Load or create the object.
  #       identifier = object['identifier'].gsub(/%2F/i, '/')
  #       new_object = IntellectualObject.where(identifier: identifier).first ||
  #           IntellectualObject.new()
  #       new_object.state = 'A' # in case we just loaded a deleted object
  #       # Set the object's attributes from the JSON data.,
  #       # then authorize and save it.
  #       object.each { |attr_name, attr_value|
  #         set_obj_attr(new_object, state, attr_name, attr_value)
  #       }
  #       state[:current_object] = "IntellectualObject #{new_object.identifier}"
  #       load_institution_for_create_from_json(new_object)
  #       authorize @institution, :create_through_institution?
  #       new_object.save!
  #       # Save the ingest and other object-level events.
  #       state[:object_events].each { |event|
  #         state[:current_object] = "IntellectualObject Event #{event['event_type']} / #{event['identifier']}"
  #         new_object.add_event(event)
  #       }
  #       # Save all the files and their events.
  #       state[:object_files].each do |file|
  #         create_generic_file(file, new_object, state)
  #       end
  #       # Save again, or we won't get our events back from Fedora!
  #       new_object.save!
  #       @intellectual_object = new_object
  #       @institution = @intellectual_object.institution
  #       respond_to { |format| format.json { render json: object_as_json, status: :created } }
  #     rescue Exception => ex
  #       log_exception(ex)
  #       if !new_object.nil?
  #         new_object.generic_files.each do |gf|
  #           gf.destroy
  #         end
  #         new_object.destroy
  #       end
  #       respond_to { |format| format.json {
  #         render json: { error: "#{ex.message} : #{state[:current_object]}" },
  #                status: :unprocessable_entity
  #       }
  #       }
  #     end
  #   end
  # end

  protected

  def redirect_after_update
    intellectual_object_path(resource)
  end

  def get_create_params
    params[:intellectual_object].is_a?(Array) ? json_param = params[:intellectual_object] : json_param = params[:intellectual_object][:_json]
  end

  def send_to_dpn
    authorize @intellectual_object, :dpn?
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if Pharos::Application.config.show_send_to_dpn_button == false
      redirect_to @intellectual_object
      flash[:alert] = 'We are not currently sending objects to DPN.'
    elsif @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has been deleted and cannot be sent to DPN.'
    elsif pending == 'false'
      WorkItem.create_dpn_request(@intellectual_object.identifier, current_user.email)
      redirect_to @intellectual_object
      flash[:notice] = 'Your item has been queued for DPN.'
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be sent to DPN at this time due to a pending #{pending} request."
    end
  end

  def restore_item
    authorize @intellectual_object, :restore?
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has been deleted and cannot be queued for restoration.'
    elsif pending == 'false'
      WorkItem.create_restore_request(@intellectual_object.identifier, current_user.email)
      redirect_to @intellectual_object
      flash[:notice] = 'Your item has been queued for restoration.'
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be queued for restoration at this time due to a pending #{pending} request."
    end
  end

  def filter_results_by_standard_params
    params[:identifier].present? ?
        @intellectual_objects = @institution.intellectual_objects :
        @intellectual_objects = IntellectualObject.all
    case params[:search_field]
      when 'title'
        @intellectual_objects = @intellectual_objects.where('title LIKE ?', "%#{params[:q]}%")
      when 'description'
        @intellectual_objects = @intellectual_objects.where('description LIKE ?', "%#{params[:q]}%")
      when 'bag_name'
        @intellectual_objects = @intellectual_objects.where('bag_name=? OR bag_name LIKE ?', params[:q], "%#{params[:q]}%")
      when 'alt_identifier'
        @intellectual_objects = @intellectual_objects.where('alt_identifier=? OR alt_identifier LIKE ?', params[:q], "%#{params[:q]}%")
      when 'identifier'
        @intellectual_objects = @intellectual_objects.where('identifier=? OR identifier LIKE ?', params[:q], "%#{params[:q]}%")
    end
  end

  def narrow_results_to_specific_institution
    if current_user.admin?
      if params[:institution].present? then
        @search_institution = Institution.where(identifier: params[:institution])
        @intellectual_objects = @search_institution.intellectual_objects
      elsif params[:identifier].present?
        @search_institution = @institution
        @intellectual_objects = @search_institution.intellectual_objects
      else
        @intellectual_objects = IntellectualObject.all
      end
    else
      @search_institution = Institution.find(current_user.institution_id)
      @intellectual_objects = @search_institution.intellectual_objects
    end
  end

  def filter_results_by_other_params
    @intellectual_objects = @intellectual_objects.where(identifier: params[:name_exact]) if params[:name_exact].present?
    @intellectual_objects = @intellectual_objects.where('identifier LIKE ?', "%#{params[:name_contains]}%") if params[:name_contains].present?
    @intellectual_objects = @intellectual_objects.where(state: params[:state]) if params[:state].present?
    if params[:updated_since].present?
      date = format_date
      @intellectual_objects = @intellectual_objects.where(updated_at: date..Time.now)
    end
  end

  def prep_search_incidentals
    @count = @intellectual_objects.count
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    start = ((page - 1) * per_page)
    @intellectual_objects = @intellectual_objects.offset(start).limit(per_page)
    @next = format_next(page, per_page)
    @previous = format_previous(page, per_page)
  end

  private

  def create_generic_file(file, intel_obj, state)
    # Create a new generic file object, or load the existing one.
    # We may have an existing generic file if this intellectual
    # object was previously deleted and is now being re-ingested.
    gfid = file['identifier'].gsub(/%2F/i, '/')
    new_file = GenericFile.where(identifier: gfid).first || GenericFile.new()
    file_events, file_checksums = []
    file.each { |file_attr_name, file_attr_value|
      case file_attr_name
        when 'premis_events'
          file_events = file_attr_value
        when 'checksum'
          file_checksums = file_attr_value
        else
          new_file[file_attr_name.to_s] = file_attr_value.to_s
      end }
    file_checksums.each { |checksum| new_file.checksums.build(checksum) }
    state[:current_object] = "GenericFile #{new_file.identifier}"
    new_file.intellectual_object = intel_obj
    new_file.state = 'A' # in case we loaded a deleted file
    # We have to save this now to get events into Solr
    new_file.save!
    file_events.each { |event|
      state[:current_object] = "GenericFile Event #{event['event_type']} / #{event['identifier']}"
      new_file.add_event(event)
    }
    # We have to save again to get events back from Fedora!
    new_file.save!
  end

  def set_obj_attr(new_object, state, attr_name, attr_value)
    case attr_name
      when 'institution_id'
        attr_value.to_s.include?(':') ? new_object.institution = Institution.find(attr_value.to_s) : new_object.institution = Institution.where(identifier: attr_value.to_s).first
      when 'premis_events'
        state[:object_events] = attr_value
      when 'generic_files'
        state[:object_files] = attr_value
      when "alt_identifier"
        new_object.alt_identifier = attr_value
      else
        new_object[attr_name.to_s] = attr_value.to_s
    end
  end

  def search_action_url options = {}
    institution_intellectual_objects_path(params[:identifier] || @intellectual_object.institution.identifier)
  end

  def object_as_json
    if params[:include_relations]
      # Return only active files, but call them generic_files
      data = @intellectual_object.serializable_hash(include: [:premis_events, active_files: { include: [:checksum, :premis_events]}])
      data[:generic_files] = data.delete(:active_files)
      data[:state] = @intellectual_object.state
      data
    else
      @intellectual_object.serializable_hash()
    end
  end

  def intellectual_object_params
    params[:intellectual_object] = params[:intellectual_object].first if params[:intellectual_object].kind_of?(Array)
    params.require(:intellectual_object).permit(:id, :institution_id, :title, :description, :access, :identifier,
                                                :bag_name, :alt_identifier, :state)
  end

  def load_object
    if params[:identifier]
      @intellectual_object = IntellectualObject.where(identifier: params[:identifier]).first
    elsif params[:esc_identifier]
      identifier = params[:esc_identifier].gsub(/%2F/i, '/')
      @intellectual_object ||= IntellectualObject.where(identifier: identifier).first
      if @intellectual_object.nil?
        msg = "IntellectualObject '#{params[:esc_identifier]}' not found"
        raise ActionController::RoutingError.new(msg)
      end
    else
      @intellectual_object ||= IntellectualObject.find(params[:id])
    end
    @institution = @intellectual_object.institution unless @intellectual_object.nil?
  end

  def load_institution
    if params[:institution_id]
      @institution ||= Institution.find(params[:institution_id])
    else
      @institution = params[:identifier].nil? ? current_user.institution : Institution.where(identifier: params[:identifier]).first
    end
  end

  def load_institution_for_create_from_json(object)
    @institution = params[:institution_id].nil? ? object.institution : Institution.find(params[:institution_id])
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def format_next(page, per_page)
    if @count.to_f / per_page <= page
      nil
    else
      new_page = page + 1
      new_url = "#{request.base_url}/member-api/v1/objects/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous(page, per_page)
    if page == 1
      nil
    else
      new_page = page - 1
      new_url = "#{request.base_url}/member-api/v1/objects/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
    str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
    str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&institution=#{params[:identifier]}" if params[:identifier].present?
    str = str << "&state=#{params[:state]}" if params[:state].present?
    str = str << "&search_field=#{params[:search_field]}" if params[:search_field].present?
    str = str << "&q=#{params[:q]}" if params[:q].present?
    str
  end
end
