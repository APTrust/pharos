class DpnWorkItemsController < ApplicationController
  include FilterCounts
  require 'uri'
  require 'net/http'
  respond_to :html, :json
  before_action :authenticate_user!
  before_action :set_item, only: [:show, :update, :requeue]
  before_action :init_from_params, only: :create
  after_action :verify_authorized

  def index
    authorize current_user, :dpn_index?
    @institution = current_user.institution
    @dpn_items = DpnWorkItem.all
    filter_sort_and_count
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
      if @dpn_item.task == 'ingest' || @dpn_item.task == 'replication' || @dpn_item.task == 'fixity'
        if @dpn_item.task == 'ingest' || @dpn_item.task == 'replication'
          (params[:delete_state_item] && params[:delete_state_item] == 'true') ? delete_state = 'true' : delete_state = 'false'
          @dpn_item.requeue_item(delete_state)
          response = issue_requeue_http_post(params[:task])
        elsif @dpn_item.task == 'fixity'
          stage = params[:stage]
          @dpn_item.fixity_requeue(stage)
          response = issue_requeue_http_post(stage)
        end
        respond_to do |format|
          format.json { render json: { status: response.code, body: response.body } }
          format.html {
            render 'show'
            flash[:notice] = response.body
          }
        end
      else
        respond_to do |format|
          format.json { render :json => { status: 'error', message: 'This DPN Item is not eligible for requeue.' }, :status => :conflict }
          format.html { }
        end
      end
    else
      authorize current_user, :nil_index?
      respond_to do |format|
        format.json { render nothing: true, status: :not_found }
        format.html { redirect_to root_url, alert: 'That DPN Work Item could not be found.' }
      end
    end
  end

  private

  def init_from_params
    @dpn_item = DpnWorkItem.new(dpn_work_item_params)
  end

  def dpn_work_item_params
    if request.method != 'GET'
      params.require(:dpn_work_item).permit(:remote_node, :processing_node, :task, :identifier, :queued_at, :completed_at, :note, :state, :pid, :stage, :status)
    end
  end

  def params_for_update
    params.require(:dpn_work_item).permit(:remote_node, :processing_node, :task, :identifier, :queued_at, :completed_at, :note, :state, :pid, :stage, :status)
  end

  def set_item
    @dpn_item = DpnWorkItem.readable(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
  end

  def issue_requeue_http_post(task_or_stage)
    if @dpn_item.task == 'replication'
      if task_or_stage == 'copy'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_copy_topic")
      elsif task_or_stage == 'validation'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_validation_topic")
      elsif task_or_stage == 'store'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_replication_store_topic")
      end
    elsif @dpn_item.task == 'ingest'
      if task_or_stage == 'package'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_package_topic")
      elsif task_or_stage == 'store'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_ingest_store_topic")
      elsif task_or_stage == 'record'
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_record_topic")
      end
    elsif @dpn_item.task == 'fixity'
      if task_or_stage == Pharos::Application::PHAROS_STAGES['requested']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_glacier_restore_topic")
      elsif task_or_stage == Pharos::Application::PHAROS_STAGES['validate']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_fixity_topic")
      elsif task_or_stage == Pharos::Application::PHAROS_STAGES['available_in_s3']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_s3_download_topic")
      end
    end
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request.body = @dpn_item.id.to_s
    http.request(request)
  end

  def filter_sort_and_count
    params[:status] = nil if params[:status] == 'Null Status'
    params[:stage] = nil if params[:stage] == 'Null Stage'
    @dpn_items = @dpn_items
                     .with_task(params[:task])
                     .with_identifier(params[:identifier])
                     .with_state(params[:state])
                     .with_stage(params[:stage])
                     .with_status(params[:status])
                     .with_retry(params[:retry])
                     .with_pid(params[:pid])
                     .queued_before(params[:queued_before])
                     .queued_after(params[:queued_after])
                     .completed_before(params[:completed_before])
                     .completed_after(params[:completed_after])
                     .is_completed(params[:is_completed])
                     .is_not_completed(params[:is_not_completed])
                     .with_remote_node(params[:remote_node])
                     .queued(params[:queued])
    @selected = {}
    get_node_counts(@dpn_items)
    get_queued_counts(@dpn_items)
    get_status_counts(@dpn_items)
    get_stage_counts(@dpn_items)
    get_retry_counts(@dpn_items)
    count = @dpn_items.count
    set_page_counts(count)
    params[:sort] = 'queued_at DESC' unless params[:sort]
    @dpn_items = @dpn_items.order(params[:sort])
  end

end
