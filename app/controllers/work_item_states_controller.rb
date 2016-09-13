class WorkItemStatesController < ApplicationController
  respond_to :html, :json
  before_filter :authenticate_user!
  before_filter :set_item_and_state, only: [:show, :update]
  before_filter :init_from_params, only: :create
  after_action :verify_authorized

  def create
    authorize @state_item
    respond_to do |format|
      if @state_item.save
        format.json { render json: @state_item, status: :created }
      else
        format.json { render json: @state_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @state_item.update(params_for_update) if @state_item
    authorize @state_item
    respond_to do |format|
      if @state_item.save
        format.json { render json: @state_item, status: :ok }
      else
        format.json { render json: @state_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    if @state_item.nil?
      authorize current_user, :state_show?
      render nothing: true, status: :not_found and return
    else
      authorize @state_item
      respond_to do |format|
        format.json { render json: @state_item.serializable_hash }
      end
    end
  end

  private

  def init_from_params
    @state_item = WorkItemState.new(work_item_state_params)
  end

  def work_item_state_params
    if request.method == 'GET'
      params.require(:work_item_id)
    else
      params.require(:work_item_state).permit(:work_item_id, :action, :state)
    end
  end

  def params_for_update
    params.require(:work_item_state).permit(:action, :state)
  end

  def set_item_and_state
    if params[:work_item_id]
      @work_item = WorkItem.find(params[:work_item_id])
      @state_item = @work_item.work_item_state
    elsif params[:id]
      @state_item = WorkItemState.find(params[:id])
      @work_item = @state_item.work_item
    end
  end
end
