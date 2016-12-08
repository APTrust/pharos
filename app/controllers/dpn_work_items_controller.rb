class DpnWorkItemsController < ApplicationController
  include SearchAndIndex
  respond_to :json
  before_filter :authenticate_user!
  before_filter :set_item, only: [:show, :update]
  before_filter :init_from_params, only: :create
  after_action :verify_authorized

  def index
    authorize current_user, :dpn_index?
    @dpn_items = DpnWorkItem.all
    filter_and_sort
    page_results(@dpn_items)
    respond_to do |format|
      format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map{ |item| item.serializable_hash } } }
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
      render nothing: true, status: :not_found and return
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
      render nothing: true, status: :not_found and return
    else
      authorize @dpn_item
      respond_to do |format|
        format.json { render json: @dpn_item.serializable_hash }
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

  def filter_and_sort
    @dpn_items = @dpn_items
                     .with_remote_node(params[:remote_node])
                     .with_task(params[:task])
                     .with_identifier(params[:identifier])
                     .with_state(params[:state])
                     .queued_before(params[:queued_before])
                     .queued_after(params[:queued_after])
                     .completed_before(params[:completed_before])
                     .completed_after(params[:completed_after])
    @dpn_items = @dpn_items.order('queued_at DESC')
    count = @dpn_items.count
    set_page_counts(count)
  end
end
