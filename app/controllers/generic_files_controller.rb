class GenericFilesController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
  before_filter :load_generic_file, only: [:show, :update, :destroy]
  before_filter :load_intellectual_object, only: [:create, :create_batch]
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
          @generic_files = GenericFile.joins(:intellectual_object).where('intellectual_objects.institution_id = ?', @institution.id)
        end
      end
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
      filter
      sort
      page_results(@generic_files)
      (params[:with_ingest_state] == 'true' && current_user.admin?) ? options_hash = {include: [:ingest_state]} : options_hash = {}
      respond_to do |format|
        format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map { |f| f.serializable_hash(options_hash) } } }
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
      attributes = { event_type: Pharos::Application::PHAROS_EVENT_TYPES['delete'],
                     date_time: Time.now.utc.iso8601,
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

  def single_generic_file_params
    params[:generic_file] &&= params.require(:generic_file)
      .permit(:id, :uri, :identifier, :size, :ingest_state, :last_fixity_check,
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
      .permit(files: [:id, :uri, :identifier, :size, :ingest_state, :last_fixity_check,
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
    fix_embedded_question_marks if params[:c]
    if params[:generic_file_identifier]
      identifier = params[:generic_file_identifier]
      @generic_file = GenericFile.where(identifier: identifier).first
      # PivotalTracker https://www.pivotaltracker.com/story/show/140235557
      if @generic_file.nil? && looks_like_fedora_file(identifier)
        fixed_identifier = fix_fedora_filename(identifier)
        if fixed_identifier != identifier
          logger.info("Rewrote #{identifier} -> #{fixed_identifier}")
          @generic_file = GenericFile.where(identifier: fixed_identifier).first
        end
      end
    elsif params[:id]
      @generic_file ||= GenericFile.find(params[:id])
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

  def fix_embedded_question_marks
    whole_identifier = "#{params[:generic_file_identifier]}?c=#{params[:c]}"
    params[:generic_file_identifier] = whole_identifier
  end


  def filter
    set_filter_values
    initialize_filter_counters
    filter_by_state unless params[:state].nil?
    filter_by_format unless params[:file_format].nil?
    set_format_count(@generic_files, :file)
    count = @generic_files.count
    set_page_counts(count)
  end

  def set_filter_values
    params[:file_format] ? @formats = [params[:file_format]] : @formats = @generic_files.distinct.pluck(:file_format)
  end
end
