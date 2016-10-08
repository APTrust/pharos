class GenericFilesController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
  before_filter :load_generic_file, only: [:show, :update, :destroy]
  before_filter :load_intellectual_object, only: [:update, :create, :create_batch]
  after_action :verify_authorized

  def index
    if params[:alt_action]
      case params[:alt_action]
        when 'file_summary'
          load_intellectual_object
          authorize @intellectual_object
          file_summary
        when 'not_checked_since'
          authorize current_user, :not_checked_since?
          not_checked_since
      end
    else
      load_parent_object
      if @intellectual_object
        authorize @intellectual_object
        @generic_files = GenericFile.where(intellectual_object_id: @intellectual_object.id)
      else
        authorize @institution, :index_through_institution?
        @generic_files = GenericFile.joins(:intellectual_object).where('intellectual_objects.institution_id = ?', @institution.id)
      end
      @generic_files = @generic_files
        .with_identifier(params[:identifier])
        .with_identifier_like(params[:identifier_like])
        .with_uri(params[:uri])
        .with_uri_like(params[:uri_like])
        .created_before(params[:created_before])
        .created_after(params[:created_after])
        .updated_before(params[:updated_before])
        .updated_after(params[:updated_after])
      filter
      sort
      page_results(@generic_files)
      respond_to do |format|
        format.json {
          @active_results = @generic_files.where(state: 'A')
          render json: @active_results.map do |f| f.serializable_hash end
        }
        format.html { }
      end
    end
  end

  def show
    authorize @generic_file
    respond_to do |format|
      format.json { render json: object_as_json }
      format.html {
        @events = Kaminari.paginate_array(@generic_file.premis_events).page(params[:page]).per(10)
      }
    end
  end

  def create
    authorize @intellectual_object
    @generic_file = @intellectual_object.generic_files.new(single_generic_file_params)
    @generic_file.state = 'A'
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
        @generic_files.push(file)
      end
      raise ActiveRecord::Rollback
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
      head :no_content
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
      @generic_file.soft_delete(attributes)
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been queued for file: #{@generic_file.uri}"
          redirect_to @generic_file.intellectual_object
        }
      end
    else
      redirect_to @generic_file
      flash[:alert] = "Your file cannot be deleted at this time due to a pending #{result} request."
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

  def not_checked_since
    datetime = Time.parse(params[:date]) rescue nil
    if datetime.nil?
      raise ActionController::BadRequest.new(type: 'date', e: "Param date is missing or invalid. Hint: Use format '2015-01-31T14:31:36Z'")
    end
    if current_user.admin? == false
      logger.warn("User #{current_user.email} tried to access generic_files_controller#not_checked_since")
      raise ActionController::Forbidden
    end
    @generic_files = GenericFile.find_files_in_need_of_fixity(params[:date], {rows: params[:rows], start: params[:start]})
    respond_to do |format|
      # Return active files only, not deleted files!
      format.json { render json: @generic_files.map { |gf| gf.serializable_hash(include: [:checksum]) } }
      format.html { }
    end
  end

  def single_generic_file_params
    params[:generic_file] &&= params.require(:generic_file)
      .permit(:id, :uri, :identifier, :size,
              :file_format, premis_events_attributes:
              [:identifier, :event_type, :date_time, :outcome, :id,
               :outcome_detail, :outcome_information, :detail, :object,
               :agent, :intellectual_object_id, :generic_file_id,
               :institution_id],
              checksums_attributes:
              [:datetime, :algorithm, :digest, :generic_file_id])
  end

  def batch_generic_file_params
    params[:generic_files] &&= params.require(:generic_files)
      .permit(files: [:id, :uri, :identifier, :size,
                      :file_format, premis_events_attributes:
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
      @intellectual_object = IntellectualObject.find_by_identifier(params[:intellectual_object_identifier])
    elsif params[:intellectual_object_id]
      @intellectual_object = IntellectualObject.find(params[:intellectual_object_id])
    elsif params[:institution_identifier]
      @institution = Institution.where(identifier: params[:institution_identifier]).first
    else
      @intellectual_object = GenericFile.find(params[:id]).intellectual_object
    end
  end

  def load_intellectual_object
    if params[:intellectual_object_identifier]
      @intellectual_object = IntellectualObject.find_by_identifier(params[:intellectual_object_identifier])
    elsif params[:intellectual_object_id]
      @intellectual_object = IntellectualObject.find(params[:intellectual_object_id])
    else
      @intellectual_object = GenericFile.find(params[:id]).intellectual_object
    end
  end

  def object_as_json
    if params[:include_relations]
      @generic_file.serializable_hash(include: [:checksum, :premis_events])
    else
      @generic_file.serializable_hash()
    end
  end

  def array_as_json(list_of_generic_files)
    files = list_of_generic_files.map { |gf| gf.serializable_hash(include: [:checksums, :premis_events]) }
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
      @generic_file ||= GenericFile.find_by_identifier(params[:generic_file_identifier])
    elsif params[:id]
      @generic_file ||=GenericFile.find(params[:id])
    end
    unless @generic_file.nil?
      @intellectual_object = @generic_file.intellectual_object
      @institution = @intellectual_object.institution
    end
  end

  def filter
    set_filter_values
    initialize_filter_counters
    filter_by_state unless params[:state].nil?
    filter_by_format unless params[:file_format].nil?
    filter_by_access unless params[:access].nil?
    #filter_by_institution unless params[:institution].nil?
    filter_by_object_association unless params[:object_association].nil?
    set_format_count(@generic_files)
    set_access_count(@generic_files)
    #set_inst_count(@generic_files)
    set_io_assc_count(@generic_files)
    count = @generic_files.count
    set_page_counts(count)
  end

  def set_filter_values
    #@institutions = @generic_files.joins(:intellectual_object).distinct.pluck(:institution_id)
    @accesses = %w(consortia institution restricted)
    @formats = @generic_files.distinct.pluck(:file_format)
    @object_associations = @generic_files.distinct.pluck(:intellectual_object_id)
  end
end
