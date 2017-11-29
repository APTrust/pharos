class IntellectualObjectsController < ApplicationController
  include SearchAndIndex
  inherit_resources
  before_action :authenticate_user!
  before_action :load_institution, only: [:index, :create]
  before_action :load_object, only: [:show, :edit, :update, :destroy, :send_to_dpn, :restore]
  after_action :verify_authorized

  def index
    authorize @institution
    if current_user.admin? and params[:institution_identifier]
      params[:institution_identifier] == Pharos::Application::APTRUST_ID ? user_institution = nil : user_institution = @institution
    elsif current_user.admin?
      user_institution = nil
    else
      user_institution = current_user.institution
    end
    @intellectual_objects = IntellectualObject
      .discoverable(current_user)
      .with_institution(user_institution)
      .with_institution(params[:institution_id])
      .with_description(params[:description])
      .with_description_like(params[:description_like])
      .with_identifier(params[:identifier])
      .with_identifier_like(params[:identifier_like])
      .with_alt_identifier(params[:alt_identifier])
      .with_alt_identifier_like(params[:alt_identifier_like])
      .with_bag_name(params[:bag_name])
      .with_bag_name_like(params[:bag_name_like])
      .with_etag(params[:etag])
      .with_etag_like(params[:etag_like])
      .created_before(params[:created_before])
      .created_after(params[:created_after])
      .updated_before(params[:updated_before])
      .updated_after(params[:updated_after])
    filter
    sort
    page_results(@intellectual_objects)
    (params[:with_ingest_state] == 'true' && current_user.admin?) ? options_hash = {include: [:ingest_state]} : options_hash = {}
    respond_to do |format|
      format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map { |item| item.serializable_hash(options_hash) } } }
      format.html {
        index!
      }
    end
  end

  def create
    authorize current_user, :intellectual_object_create?
    @intellectual_object = IntellectualObject.new(create_params)
    @intellectual_object.state = 'A'
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
    @institution = @intellectual_object.institution unless @intellectual_object.nil?
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
      format.json { render json: object_as_json }
      format.html { redirect_to intellectual_object_path(@intellectual_object) }
    end
  end

  def destroy
    authorize @intellectual_object, :soft_delete?
    pending = WorkItem.pending_action(@intellectual_object.identifier)
    if params[:confirmation_token]
      if params[:confirmation_token] == @intellectual_object.confirmation_token.token
        confirmed_destroy
        respond_to do |format|
          format.json { head :no_content }
          format.html {
            flash[:notice] = "Delete job has been queued for object: #{@intellectual_object.title}. Depending on the size of the object, it may take a few minutes for all associated files to be marked as deleted."
            redirect_to root_path
          }
        end
      else
        respond_to do |format|
          message = 'Your object cannot be deleted at this time due to an invalid confirmation token. ' +
              'Please contact your APTrust administrator for more information.'
          format.json {
            render :json => { status: 'error', message: message }, :status => :conflict
          }
          format.html {
            redirect_to @intellectual_object
            flash[:alert] = message
          }
        end
      end
    else
      if @intellectual_object.state == 'D'
        respond_to do |format|
          format.json { head :no_content }
          format.html {
            redirect_to @intellectual_object
            flash[:alert] = 'This item has already been deleted.'
          }
        end
      elsif pending.nil?
        log = Email.log_deletion_request(@intellectual_object)
        token = ConfirmationToken.create(intellectual_object: @intellectual_object, token: SecureRandom.hex)
        token.save!
        NotificationMailer.deletion_request(@intellectual_object, current_user, log, token).deliver!
      else
        respond_to do |format|
          message = "Your object cannot be deleted at this time due to a pending #{pending.action} request. " +
              "You may delete this object after the #{pending.action} request has completed."
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
  end

  def send_to_dpn
    authorize @intellectual_object, :dpn?
    dpn_item = nil
    message = ""
    api_status_code = :ok
    pending = WorkItem.pending_action(@intellectual_object.identifier)
    if Pharos::Application.config.show_send_to_dpn_button == false
      message = 'We are not currently sending objects to DPN.'
      api_status_code = :conflict
    elsif @intellectual_object.institution.dpn_uuid == ''
      message = 'This item cannot be sent to DPN because the depositing institution is not a DPN member.'
      api_status_code = :conflict
    elsif @intellectual_object.in_dpn?
      message = 'This item has already been sent to DPN.'
      api_status_code = :conflict
    elsif @intellectual_object.state == 'D'
      message = 'This item has been deleted and cannot be sent to DPN.'
      api_status_code = :conflict
    elsif @intellectual_object.too_big?
      message = 'This item cannot be sent to DPN at this time because it is greater than 250GB.'
      api_status_code = :conflict
    elsif pending.nil?
      dpn_item = WorkItem.create_dpn_request(@intellectual_object.identifier, current_user.email)
      message = 'Your item has been queued for DPN.'
    else
      message = "Your object cannot be sent to DPN at this time due to a pending #{pending.action} request."
      api_status_code = :conflict
    end
    respond_to do |format|
      status = dpn_item.nil? ? 'error' : 'ok'
      item_id = dpn_item.nil? ? 0 : dpn_item.id
      format.json {
        if status == 'ok'
          render :json => dpn_item, :status => api_status_code
        else
          render :json => { status: status, message: message }, :status => api_status_code
        end
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

  def restore
    authorize @intellectual_object, :restore?
    message = ""
    api_status_code = :ok
    restore_item = nil
    pending = WorkItem.pending_action(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      api_status_code = :conflict
      message = 'This item has been deleted and cannot be queued for restoration.'
    elsif pending.nil?
      restore_item = WorkItem.create_restore_request(@intellectual_object.identifier, current_user.email)
      message = 'Your item has been queued for restoration.'
    else
      api_status_code = :conflict
      message = "Your object cannot be queued for restoration at this time due to a pending #{pending.action} request."
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

  private

  def object_as_json
    include_list = []
    include_list.push(:premis_events, active_files: {include: [:checksums, :premis_events]}) if params[:include_all_relations]
    include_list.push(:premis_events) if params[:include_events]
    include_list.push(active_files: {include: [:checksums]}) if params[:include_files]
    include_list.push(:ingest_state) if (params[:with_ingest_state] == 'true' && current_user.admin?)
    options_hash = {include: include_list}
    data = @intellectual_object.serializable_hash(options_hash)
    data[:state] = @intellectual_object.state
    data[:generic_files] = data.delete('active_files') if params[:include_all_relations] || params[:include_files]
    data
  end

  def create_params
    params.require(:intellectual_object).permit(:institution_id, :title, :etag,
                                                :description, :access, :identifier,
                                                :bag_name, :alt_identifier, :ingest_state,
                                                generic_files_attributes:
                                                [:id, :uri, :identifier,
                                                 :size, :created, :modified, :file_format,
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
    params.require(:intellectual_object).permit(:title, :description, :access, :ingest_state,
                                                :alt_identifier, :state, :dpn_uuid, :etag)
  end

  def load_object
    if params[:intellectual_object_identifier]
      @intellectual_object = IntellectualObject.where(identifier: params[:intellectual_object_identifier]).first
      if @intellectual_object.nil?
        msg = "IntellectualObject '#{params[:intellectual_object_identifier]}' not found"
        raise ActionController::RoutingError.new(msg)
      end
    else
      @intellectual_object ||= IntellectualObject.readable(current_user).find(params[:id])
    end
    @institution = @intellectual_object.institution unless @intellectual_object.nil?
  end

  def load_institution
    if current_user.admin? and params[:institution_id]
      @institution = Institution.find(params[:institution_id])
    elsif current_user.admin? and params[:institution_identifier]
      @institution = Institution.where(identifier: params[:institution_identifier]).first
    else
      @institution = current_user.institution
    end
  end

  def confirmed_destroy
    requesting_user = User.find(params[:requesting_user_id])
    attributes = { event_type: Pharos::Application::PHAROS_EVENT_TYPES['delete'],
                   date_time: "#{Time.now}",
                   detail: 'Object deleted from S3 storage',
                   outcome: 'Success',
                   outcome_detail: requesting_user.email,
                   object: 'Goamz S3 Client',
                   agent: 'https://github.com/crowdmob/goamz',
                   outcome_information: "Action requested by user from #{requesting_user.institution_id}",
                   identifier: SecureRandom.uuid
    }
    @intellectual_object.soft_delete(attributes)
    log = Email.log_deletion_confirmation(@intellectual_object)
    NotificationMailer.deletion_confirmation(@intellectual_object, requesting_user, log).deliver!
  end

  def filter
    set_filter_values
    initialize_filter_counters
    filter_by_institution unless params[:institution].nil?
    filter_by_access unless params[:access].nil?
    filter_by_state unless params[:state].nil?
    filter_by_format unless params[:file_format].nil?
    set_inst_count(@intellectual_objects, :objects)
    set_format_count(@intellectual_objects, :object)
    count = @intellectual_objects.count
    set_page_counts(count)
  end

  def set_filter_values
    params[:institution] ? @institutions = [params[:institution]] : @institutions = @intellectual_objects.distinct.pluck(:institution_id)
    params[:access] ? @accesses = [params[:access]] : @accesses = %w(consortia institution restricted)
    params[:file_format] ? @formats = [params[:file_format]] : @formats = @intellectual_objects.joins(:generic_files).distinct.pluck(:file_format)
  end

end
