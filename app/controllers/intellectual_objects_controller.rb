class IntellectualObjectsController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  before_action :load_institution, only: [:index, :create]
  before_action :load_object, only: [:show, :edit, :update, :destroy, :send_to_dpn, :restore]

  def index
    authorize @institution
    # TODO: Replace alt_action param with urls /restore/ and /dpn/
    user_institution = current_user.admin? ? nil : current_user.institution
    # TODO: Add bag_name and etag. Add discoverable?
    @intellectual_objects = IntellectualObject
      .with_institution(user_institution)
      .with_institution(params[:institution_id])
      .with_description(params[:description])
      .with_description_like(params[:description_like])
      .with_identifier(params[:identifier])
      .with_identifier_like(params[:identifier_like])
      .with_alt_identifier(params[:alt_identifier])
      .with_alt_identifier_like(params[:alt_identifier_like])
      .with_state(params[:state])
      .created_before(params[:created_before])
      .created_after(params[:created_after])
      .updated_before(params[:updated_before])
      .updated_after(params[:updated_after])
    prep_search_incidentals
    respond_to do |format|
      format.json { render json: {count: @count, next: @next, previous: @previous, results: @intellectual_objects.map{ |item| item.serializable_hash(include: [:etag])}} }
      format.html {
        index!
      }
    end
  end

  def create
    authorize IntellectualObject
    @intellectual_object = IntellectualObject.new(create_params)
    @intellectual_object.institution = Institution.find_by_identifier(params[:institution_identifier])
    if @intellectual_object.save
      respond_to do |format|
        format.json { render json: @intellectual_object, status: :created }
        format.html {
          render status: :created
          super
        }
      end
    else
      respond_to do |format|
        format.json { render json: @intellectual_object.errors, status: :unprocessable_entity }
        format.html {
          render status: :unprocessable_entity
          super
        }
      end
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
    @intellectual_object.update!(update_params)
    respond_to do |format|
      format.json { render object_as_json}
      format.html { redirect_to intellectual_object_path(@intellectual_object) }
    end
  end

  def destroy
    authorize @intellectual_object, :soft_delete?
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          redirect_to @intellectual_object
          flash[:alert] = 'This item has already been deleted.'
        }
      end
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
      respond_to do |format|
        message = "Your object cannot be deleted at this time due to a pending #{pending} request. " +
          "You may delete this object after the #{pending} request has completed."
        format.json {
          render :json => { status: 'error', message: message }, :status => :conflict
        }
        format.html {
          redirect_to @intellectual_object
          flash[:alert] = message
        }
      end
    end
  end

  # PUT objects/:intellectual_object_identifier/dpn
  # TODO: Expose this in the member API
  def send_to_dpn
    authorize @intellectual_object, :dpn?
    dpn_item = nil
    message = ""
    api_status_code = :ok
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if Pharos::Application.config.show_send_to_dpn_button == false
      message = 'We are not currently sending objects to DPN.'
      api_status_code = :conflict
    elsif @intellectual_object.in_dpn?
      message = 'This item has already been sent to DPN.'
      api_status_code = :conflict
    elsif @intellectual_object.state == 'D'
      message = 'This item has been deleted and cannot be sent to DPN.'
      api_status_code = :conflict
    elsif pending == 'false'
      dpn_item = WorkItem.create_dpn_request(@intellectual_object.identifier, current_user.email)
      message = 'Your item has been queued for DPN.'
    else
      message = "Your object cannot be sent to DPN at this time due to a pending #{pending} request."
      api_status_code = :conflict
    end
    respond_to do |format|
      status = dpn_item.nil? ? 'error' : 'ok'
      item_id = dpn_item.nil? ? 0 : dpn_item.id
      format.json {
        render :json => { status: status, message: message, work_item_id: item_id }, :status => api_status_code
      }
      format.html {
        if dpn_item.nil?
          flash[:alert] = message
        else
          flash[:notice] = message
        end
        redirect_to @intellectual_object
      }
    end
  end

  # PUT objects/:intellectual_object_identifier/restore
  # TODO: Expose this in the member API
  def restore
    authorize @intellectual_object, :restore?
    message = ""
    api_status_code = :ok
    restore_item = nil
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      api_status_code = :conflict
      message = 'This item has been deleted and cannot be queued for restoration.'
    elsif pending == 'false'
      restore_item = WorkItem.create_restore_request(@intellectual_object.identifier, current_user.email)
      message = 'Your item has been queued for restoration.'
    else
      api_status_code = :conflict
      message = "Your object cannot be queued for restoration at this time due to a pending #{pending} request."
    end
    respond_to do |format|
      status = restore_item.nil? ? 'error' : 'ok'
      item_id = restore_item.nil? ? 0 : restore_item.id
      format.json {
        render :json => { status: status, message: message, work_item_id: item_id }, :status => api_status_code
      }
      format.html {
        if restore_item.nil?
          flash[:alert] = message
        else
          flash[:notice] = message
        end
        redirect_to @intellectual_object
      }
    end
  end

  protected

  def redirect_after_update
    intellectual_object_path(resource)
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

  def create_params
    params.require(:intellectual_object).permit(:id, :institution_id, :title,
                                                :description, :access, :identifier,
                                                :bag_name, :alt_identifier, :state,
                                                generic_files_attributes:
                                                [:id, :uri, :content_uri, :identifier,
                                                 :size, :created, :modified, :file_format,
                                                 checksums_attributes:
                                                 [:digest, :algorithm, :datetime, :id],
                                                 premis_events_attributes:
                                                 [:id, :identifier, :event_type, :date_time,
                                                  :outcome, :outcome_detail,
                                                  :outcome_information, :detail,
                                                  :object, :agent, :intellectual_object_id,
                                                  :generic_file_id, :institution_id,
                                                  :created_at, :updated_at]],
                                                premis_events_attributes:
                                                [:id, :identifier, :event_type,
                                                 :date_time, :outcome, :outcome_detail,
                                                 :outcome_information, :detail, :object,
                                                 :agent, :intellectual_object_id,
                                                 :generic_file_id, :institution_id,
                                                 :created_at, :updated_at])

  end

  def update_params
    params.require(:intellectual_object).permit(:title, :description, :access,
                                                :alt_identifier, :state)
  end

  def load_object
    if params[:intellectual_object_identifier]
      identifier = params[:intellectual_object_identifier].gsub(/%2F/i, '/')
      @intellectual_object = IntellectualObject.where(identifier: identifier).first
      if @intellectual_object.nil?
        msg = "IntellectualObject '#{params[:intellectual_object_identifier]}' not found"
        raise ActionController::RoutingError.new(msg)
      end
    else
      @intellectual_object ||= IntellectualObject.find(params[:id])
    end
    @institution = @intellectual_object.institution unless @intellectual_object.nil?
  end

  def load_institution
    if current_user.admin? and params[:institution_id]
      @institution = Institution.find(params[:institution_id])
    else
      @institution = current_user.institution
    end
  end

  def format_next(page, per_page)
    if @count.to_f / per_page <= page
      nil
    else
      path = request.fullpath.split('?').first
      new_page = page + 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous(page, per_page)
    if page == 1
      nil
    else
      path = request.fullpath.split('?').first
      new_page = page - 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
    str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
    str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&institution=#{params[:institution_identifier]}" if params[:institution_identifier].present?
    str = str << "&state=#{params[:state]}" if params[:state].present?
    str = str << "&search_field=#{params[:search_field]}" if params[:search_field].present?
    str = str << "&q=#{params[:q]}" if params[:q].present?
    str
  end
end
