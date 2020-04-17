class StorageRecordsController < InheritedResources::Base

  # Index is the only method for this controller, and it's admin-only.
  # There is no update for StorageRecords, and creating and deletion
  # are handled through the GenericFilesController.

  # GET 'api/v2/storage_records/:generic_file_identifier'
  def index
    if params[:generic_file_identifier].blank?
      render json: { error: "Param generic_file_identifier is required" }, :status => :bad_request
    end
    @records = StorageRecord.where(generic_file_identifier: params[:generic_file_identifier])
    page_results(@records)
    format.json { render json: {count: @count, next: @next, previous: @previous, results: @records} }
  end

  private

  def storage_record_params
    params.require(:storage_record).permit(:generic_file_identifier)
  end

end
