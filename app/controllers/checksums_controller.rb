class ChecksumsController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
  before_filter :load_generic_file, only: :create
  after_action :verify_authorized

  def index
    authorize current_user, :checksum_index?
    @checksums = Checksum.all
    filter_and_sort
    page_results(@checksums)
    respond_to do |format|
      format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map{ |cs| cs.serializable_hash } } }
    end
  end

  def create
    authorize @generic_file, :create_through_generic_file?
    @checksum = @generic_file.checksums.new(checksum_params)
    respond_to do |format|
      if @checksum.save
        format.json { render json: @checksum.serializable_hash, status: :created }
      else
        log_model_error(@checksum)
        format.json { render json: @checksum.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def checksum_params
    if request.method != 'GET'
      params[:checksum] &&= params.require(:checksum).permit(:datetime, :algorithm, :digest)
    end
  end

  def load_generic_file
    if params[:generic_file_identifier]
      @generic_file = GenericFile.find_by_identifier(params[:generic_file_identifier])
    elsif params[:generic_file_id]
      @generic_file = GenericFile.find(params[:generic_file_id])
    end
  end

  def filter_and_sort
    @checksums = @checksums
      .with_generic_file_identifier(params[:generic_file_identifier])
      .with_algorithm(params[:algorithm])
      .with_digest(params[:digest])
    @checksums = @checksums.order('created_at DESC')
    count = @checksums.count
    set_page_counts(count)
  end

end
