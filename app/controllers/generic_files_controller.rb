class GenericFilesController < ApplicationController
  include FilterCounts
  respond_to :html, :json
  before_action :authenticate_user!
  before_action :load_generic_file, only: [:show, :update, :destroy, :confirm_destroy, :finished_destroy, :restore]
  before_action :load_intellectual_object, only: [:create, :create_batch]
  before_action :set_format
  after_action :verify_authorized

  def index
    if params[:alt_action]
      case params[:alt_action]
        when 'file_summary'
          load_intellectual_object
          authorize @intellectual_object
          file_summary
      end
    else
      if params[:not_checked_since]
        authorize current_user, :not_checked_since?
        @generic_files = GenericFile.not_checked_since(params[:not_checked_since])
      else
        load_parent_object
        if @intellectual_object
          authorize @intellectual_object
          @generic_files = GenericFile.where(intellectual_object_id: @intellectual_object.id)
        else
          authorize @institution, :index_through_institution?
          (current_user.admin? && @institution.identifier == Pharos::Application::APTRUST_ID) ? @generic_files = GenericFile.all : @generic_files = GenericFile.with_institution(@institution.id)
        end
      end
      filter_count_and_sort
      page_results(@generic_files)
      (params[:with_ingest_state] == 'true' && current_user.admin?) ? options_hash = {include: [:ingest_state]} : options_hash = {}
      respond_to do |format|
        format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map { |f| f.serializable_hash(options_hash) } } }
        format.html { }
      end
    end
  end

  def show
    if @generic_file
      authorize @generic_file
      respond_to do |format|
        format.json { render json: object_as_json }
        format.html {
          @events = Kaminari.paginate_array(@generic_file.premis_events).page(params[:page]).per(10)
        }
      end
    else
      authorize current_user, :nil_file?
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'This file could not be found. Please check to make sure the identifier was properly escaped.' }, status: :not_found }
        format.html { redirect_to root_url, alert: "A Generic File with identifier: #{params[:generic_file_identifier]} was not found. Please check to make sure the identifier was properly escaped." }
      end
    end
  end

  def create
    authorize current_user, :object_create?
    @generic_file = @intellectual_object.generic_files.new(single_generic_file_params)
    @generic_file.state = 'A'
    @generic_file.institution_id = @intellectual_object.institution_id
    respond_to do |format|
      if @generic_file.save
        format.json { render json: object_as_json, status: :created }
      else
        log_model_error(@generic_file)
        format.json { render json: @generic_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # This method is open to admin only, through the admin API.
  def create_batch
    authorize @intellectual_object, :create?
    begin
      files = JSON.parse(request.body.read)
    rescue JSON::ParserError, Exception => e
      respond_to do |format|
        format.json { render json: {error: "JSON parse error: #{e.message}"}, status: 400 } and return
      end
    end
    GenericFile.transaction do
      @generic_files = []
      files.each do |gf|
        file = @intellectual_object.generic_files.new(gf)
        file.state = 'A'
        file.institution_id = @intellectual_object.institution_id
        @generic_files.push(file)
      end
    end
    respond_to do |format|
      if @intellectual_object.save
        format.json { render json: array_as_json(@generic_files), status: :created }
      else
        errors = @generic_files.map(&:errors)
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    # A.D. Aug. 3, 2016: Deleted batch update because
    # nested params cause new events to be created,
    # and it would require too much logic to determine which
    # events should not be duplicated.
    authorize @generic_file
    @generic_file.state = 'A'
    if resource.update(single_generic_file_params)
      render json: object_as_json, status: :ok
    else
      log_model_error(resource)
      render json: resource.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @generic_file, :soft_delete?
    # Don't allow a delete request if an ingest or restore is in process
    # for this object. OK to delete if another delete request is in process.
    result = WorkItem.can_delete_file?(@generic_file.intellectual_object.identifier, @generic_file.identifier)
    if @generic_file.state == 'D'
      redirect_to @generic_file
      flash[:alert] = 'This file has already been deleted.'
    elsif result == 'true'
      log = Email.log_deletion_request(@generic_file)
      ConfirmationToken.where(generic_file_id: @generic_file.id).delete_all #delete any old tokens. Only the new one should be valid
      token = ConfirmationToken.create(generic_file: @generic_file, token: SecureRandom.hex)
      token.save!
      NotificationMailer.deletion_request(@generic_file, current_user, log, token).deliver!
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          redirect_to @generic_file
          flash[:notice] = 'An email has been sent to the administrators of this institution to confirm deletion of this file.'
        }
      end
    else
      redirect_to @generic_file
      flash[:alert] = "Your file cannot be deleted at this time due to a pending #{result} request."
    end
  end

  def confirm_destroy
    authorize @generic_file, :soft_delete?
    if @generic_file.confirmation_token.nil? && (WorkItem.with_action(Pharos::Application::PHAROS_ACTIONS('delete')).with_file_identifier(@generic_file.identifier).count == 1)
      respond_to do |format|
        message = 'This deletion request has already been confirmed and queued for deletion by someone else.'
        format.json {
          render :json => { status: 'ok', message: message }, :status => :ok
        }
        format.html {
          redirect_to @generic_file
          flash[:notice] = message
        }
      end
    else
      if params[:confirmation_token] == @generic_file.confirmation_token.token
        confirmed_destroy
        respond_to do |format|
          format.json { head :no_content }
          format.html {
            flash[:notice] = "Delete job has been queued for file: #{@generic_file.uri}."
            redirect_to @generic_file.intellectual_object
          }
        end
      else
        respond_to do |format|
          message = 'Your file cannot be deleted at this time due to an invalid confirmation token. ' +
              'Please contact your APTrust administrator for more information.'
          format.json {
            render :json => { status: 'error', message: message }, :status => :conflict
          }
          format.html {
            redirect_to @generic_file
            flash[:alert] = message
          }
        end
      end
    end
  end

  def finished_destroy
    authorize @generic_file
    @generic_file.mark_deleted
    respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been finished for file: #{@generic_file.uri}. File has been marked as deleted."
          redirect_to @generic_file.intellectual_object
        }
    end
  end


  def restore
    authorize @generic_file, :restore?
    message = ""
    api_status_code = :ok
    restore_item = nil
    pending = WorkItem.pending_action_for_file(@generic_file.identifier)
    if @generic_file.state == 'D'
      api_status_code = :conflict
      message = 'This file has been deleted and cannot be queued for restoration.'
    elsif pending.nil?
      restore_item = WorkItem.create_restore_request_for_file(@generic_file, current_user.email)
      message = 'Your file has been queued for restoration.'
    else
      api_status_code = :conflict
      message = "Your file cannot be queued for restoration at this time due to a pending #{pending.action} request."
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
        redirect_to @generic_file
      }
    end
  end

  protected

  def file_summary
    data = []
    files = @intellectual_object.active_files
    files.each do |file|
      summary = {}
      summary['size'] = file.size
      summary['identifier'] = file.identifier
      summary['uri'] = file.uri
      data << summary
    end
    respond_to do |format|
      format.json { render json: data }
      format.html { super }
    end
  end

  def single_generic_file_params
    params[:generic_file] &&= params.require(:generic_file)
      .permit(:id, :uri, :identifier, :size, :ingest_state, :last_fixity_check,
              :file_format, :storage_option, premis_events_attributes:
              [:identifier, :event_type, :date_time, :outcome, :id,
               :outcome_detail, :outcome_information, :detail, :object,
               :agent, :intellectual_object_id, :generic_file_id,
               :institution_id],
              checksums_attributes:
              [:datetime, :algorithm, :digest, :generic_file_id])
  end

  def batch_generic_file_params
    params[:generic_files] &&= params.require(:generic_files)
      .permit(files: [:id, :uri, :identifier, :size, :ingest_state, :last_fixity_check,
                      :file_format, :storage_option, premis_events_attributes:
                      [:identifier, :event_type, :date_time, :outcome, :id,
                       :outcome_detail, :outcome_information, :detail, :object,
                       :agent, :intellectual_object_id, :generic_file_id,
                       :institution_id],
                      checksums_attributes:
                      [:datetime, :algorithm, :digest, :generic_file_id]])
  end

  def resource
    @generic_file
  end

  def load_parent_object
    if params[:intellectual_object_identifier]
      @intellectual_object = IntellectualObject.readable(current_user).find_by_identifier(params[:intellectual_object_identifier])
    elsif params[:intellectual_object_id]
      @intellectual_object = IntellectualObject.readable(current_user).find(params[:intellectual_object_id])
    elsif params[:institution_identifier]
      @institution = Institution.where(identifier: params[:institution_identifier]).first
    else
      @intellectual_object = GenericFile.readable(current_user).find(params[:id]).intellectual_object
    end
  end

  def load_intellectual_object
    if params[:intellectual_object_identifier]
      @intellectual_object = IntellectualObject.readable(current_user).find_by_identifier(params[:intellectual_object_identifier])
    elsif params[:intellectual_object_id]
      @intellectual_object = IntellectualObject.readable(current_user).find(params[:intellectual_object_id])
    else
      @intellectual_object = GenericFile.readable(current_user).find(params[:id]).intellectual_object
    end
  end

  def object_as_json
    if params[:with_ingest_state] == 'true' && current_user.admin? && params[:include_relations]
      options_hash = {include: [:checksums, :premis_events, :ingest_state]}
    elsif params[:with_ingest_state] == 'true' && current_user.admin?
      options_hash = {include: [:ingest_state]}
    elsif params[:include_relations]
      options_hash = {include: [:checksums, :premis_events]}
    else
      options_hash = {}
    end
    @generic_file.serializable_hash(options_hash)
  end

  def array_as_json(list_of_generic_files)
    (params[:with_ingest_state] == 'true' && current_user.admin?) ?
        options_hash = {include: [:checksums, :premis_events, :ingest_state]} :
        options_hash = {include: [:checksums, :premis_events]}
    files = list_of_generic_files.map { |gf| gf.serializable_hash(options_hash) }

    # For consistency on the client end, make this list
    # look like every other list the API returns.
    {
      count: files.count,
      next: nil,
      previous: nil,
      results: files,
    }
  end

  def load_generic_file
    if params[:generic_file_identifier]
      identifier = params[:generic_file_identifier]
      @generic_file = GenericFile.where(identifier: identifier).first
      # PivotalTracker https://www.pivotaltracker.com/story/show/140235557
      if @generic_file.nil?
          if looks_like_fedora_file(identifier)
            fixed_identifier = fix_fedora_filename(identifier)
            if fixed_identifier != identifier
              logger.info("Rewrote #{identifier} -> #{fixed_identifier}")
              @generic_file = GenericFile.where(identifier: fixed_identifier).first
            end
          else
            @generic_file = GenericFile.find_by_identifier(identifier)
          end
      end
    elsif params[:id]
      @generic_file ||= GenericFile.readable(current_user).find(params[:id])
    end
    unless @generic_file.nil?
      @intellectual_object = @generic_file.intellectual_object
      @institution = @intellectual_object.institution
    end
  end

  # If this looks like a file that Fedora exported,
  # it will need some special handling.
  def looks_like_fedora_file(filename)
    filename.include?('fedora') || filename.include?('datastreamStore')
  end

  # Oh, the horror!
  # https://www.pivotaltracker.com/story/show/140235557
  def fix_fedora_filename(filename)
    match = filename.match(/\/[0-9a-f]{2}\//)
    return filename if match.nil?

    # Split the filename at the dirname after datastreamStore or objectStore.
    # That dirname always consists of two hex letters.
    dirname = match[0]
    parts = filename.split(dirname, 2)

    return filename if parts.count < 2

    # Now URL-encode slashes and colons AFTER the dirname,
    # and use capitals, because Postgres is case-sensitive.
    # Second arg to URI.encode forces it to escape slashes
    # and colons, which the encoder would otherwise let through
    start_of_name = parts[0]
    end_of_name = parts[1]
    encoded_end = URI.encode(end_of_name, "/:")

    # Now rebuild and return the fixed file name.
    return "#{start_of_name}#{dirname}#{encoded_end}"
  end

  def filter_count_and_sort
    params[:state] = 'A' if params[:state].nil?
    @generic_files = @generic_files
                         .with_identifier(params[:identifier])
                         .with_identifier_like(params[:identifier_like])
                         .with_uri(params[:uri])
                         .with_uri_like(params[:uri_like])
                         .created_before(params[:created_before])
                         .created_after(params[:created_after])
                         .updated_before(params[:updated_before])
                         .updated_after(params[:updated_after])
                         .with_institution(params[:institution])
                         .with_file_format(params[:file_format])
                         .with_state(params[:state])
    @selected = {}
    get_format_counts(@generic_files)
    get_institution_counts(@generic_files)
    get_state_counts(@generic_files)
    count = @generic_files.count
    set_page_counts(count)
    case params[:sort]
      when 'date'
        @generic_files = @generic_files.order('updated_at DESC')
      when 'name'
        @generic_files = @generic_files.order('identifier').reverse_order
      when 'institution'
        @generic_files = @generic_files.joins(:institution).order('institutions.name')
    end
  end

  private

  def set_format
    request.format = 'html' unless request.format == 'json' || request.format == 'html'
  end

  def confirmed_destroy
    requesting_user = User.find(params[:requesting_user_id])
    attributes = { requestor: requesting_user.email,
                   inst_app: current_user.email
    }
    @generic_file.soft_delete(attributes)
    log = Email.log_deletion_confirmation(@generic_file)
    NotificationMailer.deletion_confirmation(@generic_file, requesting_user.id, current_user.id, log).deliver!
    ConfirmationToken.where(generic_file_id: @generic_file.id).delete_all
  end
end
