class GenericFilesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_generic_file, only: [:show, :update, :destroy]
  before_filter :load_intellectual_object, only: [:update, :create]
  after_action :verify_authorized, :except => [:index]

  def index
    if params[:alt_action]
      case params[:alt_action]
        when 'file_summary'
          load_intellectual_object
          authorize @intellectual_object
          file_summary
        when 'not_checked_since'
          not_checked_since
      end
    else
      load_intellectual_object
      authorize @intellectual_object
      @generic_files = @intellectual_object.generic_files
      respond_to do |format|
        format.json { render json: @intellectual_object.active_files.map do |f| f.serializable_hash end }
        format.html { super }
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
    authorize @intellectual_object, :create_through_intellectual_object?
    if params[:save_batch]
      GenericFile.transaction do
        batch_generic_file_params
        @generic_files = []
        params[:generic_files][:files].each do |gf|
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
    else
      @generic_file = @intellectual_object.generic_files.new(generic_file_params)
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
  end

  def update
    # A.D. Aug. 3, 2016: Deleted batch update because
    # nested params cause new events and checksums to be created,
    # and it would require too much logic to determine which
    # events and checksums should not be duplicated.
    authorize @generic_file
    @generic_file.state = 'A'
    if resource.update(params_for_update)
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
    files = GenericFile.where(state: 'A', intellectual_object_id: @intellectual_object.id)
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

  def generic_file_params
    params[:generic_file] &&= params.require(:generic_file)
      .permit(:id, :uri, :identifier, :size, :created_at,
              :updated_at, :file_format, checksums_attributes:
              [:digest, :algorithm, :datetime, :id], premis_events_attributes:
              [:identifier, :event_type, :date_time, :outcome, :id,
               :outcome_detail, :outcome_information, :detail, :object,
               :agent, :intellectual_object_id, :generic_file_id,
               :institution_id, :created_at, :updated_at])
  end

  def batch_generic_file_params
    params[:generic_files] &&= params.require(:generic_files)
      .permit(files: [:id, :uri, :identifier, :size, :created_at,
                      :updated_at, :file_format, checksums_attributes:
                      [:digest, :algorithm, :datetime, :id], premis_events_attributes:
                      [:identifier, :event_type, :date_time, :outcome, :id,
                       :outcome_detail, :outcome_information, :detail, :object,
                       :agent, :intellectual_object_id, :generic_file_id,
                       :institution_id, :created_at, :updated_at]])
  end

  def params_for_update
    params[:generic_file] &&= params.require(:generic_file).
      permit(:uri, :identifier, :size, :created_at,
             :updated_at, :file_format)
  end

  def resource
    @generic_file
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
    list_of_generic_files.map { |gf| gf.serializable_hash(include: [:checksums, :premis_events]) }
  end

  def remove_existing_checksums(generic_file, gf_params)
    copy_of_params = gf_params.deep_dup
    generic_file.checksum.each do |existing_checksum|
      copy_of_params[:checksum_attributes].delete_if do |submitted_checksum|
        generic_file.has_checksum?(submitted_checksum[:digest])
      end
    end
    copy_of_params
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
end
