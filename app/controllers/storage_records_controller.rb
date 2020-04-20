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

  private

  def storage_record_params
    params.require(:generic_file_identifier)
  end

end
