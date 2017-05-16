class DpnWorkItemsController < ApplicationController
  include SearchAndIndex
  respond_to :json
  before_action :authenticate_user!
  before_action :set_item, only: [:show, :update]
  before_action :init_from_params, only: :create
  after_action :verify_authorized

  def index
    authorize current_user, :dpn_index?
    @institution = current_user.institution
    @dpn_items = DpnWorkItem.all
    filter_and_sort
    page_results(@dpn_items)
    respond_to do |format|
      format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map{ |item| item.serializable_hash } } }
      format.html { }
    end
  end

  def create
    authorize @dpn_item
    respond_to do |format|
      if @dpn_item.save
        format.json { render json: @dpn_item, status: :created }
      else
        format.json { render json: @dpn_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @dpn_item.nil?
      authorize current_user, :dpn_show?
      render body: nil, status: :not_found and return
    else
      @dpn_item.update(params_for_update)
      authorize @dpn_item
      respond_to do |format|
        if @dpn_item.save
          format.json { render json: @dpn_item, status: :ok }
        else
          format.json { render json: @dpn_item.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def show
    if @dpn_item.nil?
      authorize current_user, :dpn_show?
      render body: nil, status: :not_found and return
    else
      authorize @dpn_item
      respond_to do |format|
        format.json { render json: @dpn_item.serializable_hash }
        format.html { }
      end
    end
  end

  def requeue
    if @dpn_item
      authorize @dpn_item
      (params[:delete_state_item] && params[:delete_state_item] == 'true') ? delete_state = 'true' : delete_state = 'false'
      @dpn_item.requeue_item(delete_state)
      response = issue_requeue_http_post(params[:task])
      respond_to do |format|
        format.json { render json: { status: response.code, body: response.body } }
        format.html {
          render 'show'
          flash[:notice] = response.body
        }
      end
    else
      authorize current_user, :nil_index?
      respond_to do |format|
        format.json { render nothing: true, status: :not_found }
        format.html { render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found }
      end
    end
  end

  private

  def init_from_params
    @dpn_item = DpnWorkItem.new(dpn_work_item_params)
  end

  def dpn_work_item_params
    if request.method != 'GET'
      params.require(:dpn_work_item).permit(:remote_node, :task, :identifier, :queued_at, :completed_at, :note, :state)
    end
  end

  def params_for_update
    params.require(:dpn_work_item).permit(:remote_node, :task, :identifier, :queued_at, :completed_at, :note, :state)
  end

  def set_item
    @dpn_item = DpnWorkItem.find(params[:id])
  rescue ActiveRecord::RecordNotFound
  end

  def issue_requeue_http_post(task)
    if @dpn_item.task == 'replication'
      if task == 'copy'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/put?topic=dpn_copy_topic")
      elsif task == 'validation'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/put?topic=dpn_validation_topic")
      elsif task == 'store'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/put?topic=dpn_replication_store_topic")
      end
    elsif @dpn_item.task == 'ingest'
      if task == 'package'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/put?topic=dpn_package_topic")
      elsif task == 'store'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/put?topic=dpn_ingest_store_topic")
      elsif task == 'record'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/put?topic=dpn_record_topic")
      end
    end
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request.body = @dpn_item.id.to_s
    http.request(request)
  end

  def filter_and_sort
    @dpn_items = @dpn_items
                     .with_task(params[:task])
                     .with_identifier(params[:identifier])
                     .with_state(params[:state])
                     .queued_before(params[:queued_before])
                     .queued_after(params[:queued_after])
                     .completed_before(params[:completed_before])
                     .completed_after(params[:completed_after])
                     .is_completed(params[:is_completed])
                     .is_not_completed(params[:is_not_completed])
    params[:sort] = 'queued_at DESC' unless params[:sort]
    @dpn_items = @dpn_items.order(params[:sort])
    @selected = {}
    initialize_filter_counters
    filter_by_node if params[:remote_node]
    filter_by_queued if params[:queued]
    count = @dpn_items.count
    set_filter_values
    set_filter_counts
    set_page_counts(count)
  end

  def set_filter_values
    params[:remote_node] ? @nodes = [params[:remote_node]] : @nodes = %w(chron hathi sdr tdr aptrust)
    @queued_filter = true
  end

  def set_filter_counts
    set_node_count(@dpn_items)
    set_queued_count(@dpn_items)
  end

end
