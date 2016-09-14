class ChecksumsController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
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

  private

  def filter_and_sort
    @checksums = @checksums.joins(:generic_file).where('generic_files.identifier = ?', "#{params[:generic_file_identifier]}") if params[:generic_file_identifier]
    @checksums = @checksums.where(algorithm: params[:algorithm]) if params[:algorithm]
    @checksums = @checksums.order('created_at DESC')
    count = @checksums.count
    set_page_counts(count)
  end

end
