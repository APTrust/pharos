class StorageRecordsController < InheritedResources::Base

  before_action :authenticate_user!
  after_action :verify_authorized

  # Index is the only method for this controller, and it's admin-only.
  # There is no update for StorageRecords, and creating and deletion
  # are handled through the GenericFilesController.

  # GET 'api/v2/storage_records/:generic_file_identifier'
  def index
    authorize StorageRecord
    params[:page] = 1 unless params[:page]
    params[:per_page] = 20 unless params[:per_page]
    gf_identifier = params[:generic_file_identifier]
    if gf_identifier.blank?
      render json: { error: "Param generic_file_identifier is required" }, :status => :bad_request and return
    end
    generic_file = GenericFile.find_by_identifier(gf_identifier)
    if generic_file.nil?
      render body: nil, status: :not_found and return
    else
      @records = generic_file.storage_records
      page_results(@records)
      respond_to do |format|
        format.json {
          render json: {count: @count, next: @next, previous: @previous, results: @records} }
      end
    end
  end

  # POST 'api/v2/storage_records/:generic_file_identifier'
  def create
    authorize StorageRecord
    generic_file = GenericFile.find_by_identifier(params[:generic_file_identifier])
    @storage_record = generic_file.storage_records.new(storage_record_params)
    respond_to do |format|
      if @storage_record.save
        format.json { render json: @storage_record.serializable_hash, status: :created }
      else
        log_model_error(storage_record)
        format.json { render json: @storage_record.errors, status: :bad_request }
      end
    end
  end

  # DELETE 'api/v2/storage_records/:id'
  def destroy
    authorize StorageRecord
    StorageRecord.destroy(params[:id])
    respond_to do |format|
      format.json { render body: nil, status: :no_content }
    end
  end

  private

  def storage_record_params
    if request.method == 'GET'
      params.require(:generic_file_identifier)
    elsif request.method == 'POST'
      params.permit(:url)
    elsif request.method == 'DELETE'
      params.require(:id)
    end
  end

end
