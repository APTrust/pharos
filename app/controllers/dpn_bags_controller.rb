class DpnBagsController < ApplicationController
  respond_to :html, :json
  before_action :authenticate_user!
  before_action :set_bag, only: [:show, :update]
  before_action :set_institution, only: :index
  before_action :init_from_params, only: :create
  after_action :verify_authorized

  def index
    authorize @institution, :dpn_bag_index?
    @dpn_bags = DpnBag.all
    filter_sort_and_count
    page_results(@dpn_bags)
    respond_to do |format|
      format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map{ |item| item.serializable_hash } } }
      format.html { }
    end
  end

  def create
    authorize @dpn_bag
    respond_to do |format|
      if @dpn_bag.save
        format.json { render json: @dpn_bag, status: :created }
      else
        format.json { render json: @dpn_bag.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    if @dpn_bag.nil?
      authorize current_user, :nil_dpn_bag?
      respond_to do |format|
        format.json { render body: nil, status: :not_found and return }
        format.html { redirect_to root_url, alert: 'That DPN Bag could not be found.' }
      end
    else
      authorize @dpn_bag
      respond_to do |format|
        format.json { render json: @dpn_bag.serializable_hash }
        format.html { }
      end
    end
  end

  def update
    if @dpn_bag.nil?
      authorize current_user, :nil_dpn_bag?
      render body: nil, status: :not_found and return
    else
      @dpn_bag.update(params_for_update)
      authorize @dpn_bag
      respond_to do |format|
        if @dpn_bag.save
          format.json { render json: @dpn_bag, status: :ok }
        else
          format.json { render json: @dpn_bag.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  private

  def init_from_params
    @dpn_bag = DpnBag.new(dpn_bag_params)
  end

  def dpn_bag_params
    if request.method != 'GET'
      params.require(:dpn_bag).permit(:institution_id, :object_identifier, :dpn_identifier, :dpn_size, :node_1, :node_2, :node_3, :dpn_created_at, :dpn_updated_at )
    end
  end

  def params_for_update
    params.require(:dpn_bag).permit(:object_identifier, :dpn_identifier, :dpn_size, :node_1, :node_2, :node_3, :dpn_created_at, :dpn_updated_at)
  end

  def set_bag
    @dpn_bag = DpnBag.readable(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
  end

  def set_institution
    if current_user.admin? and params[:institution_id]
      @institution = Institution.find(params[:institution_id])
      @inst_param = @institution.id
    elsif current_user.admin? and params[:institution_identifier]
      @institution = Institution.where(identifier: params[:institution_identifier]).first
      @inst_param = @institution.id
    else
      @institution = current_user.institution
    end
  end

  def filter_sort_and_count
    if current_user.admin? && @inst_param
      @dpn_bags = @dpn_bags.with_institution(@inst_param)
    elsif !current_user.admin?
      @dpn_bags = @dpn_bags.with_institution(current_user.institution_id)
    end
    @dpn_bags = @dpn_bags
                    .with_object_identifier(params[:object_identifier])
                    .with_dpn_identifier(params[:dpn_identifier])
                    .created_before(params[:created_before])
                    .created_after(params[:created_after])
                    .updated_before(params[:updated_before])
                    .updated_after(params[:updated_after])
    @selected = {}
    # set_filter_values
    count = @dpn_bags.count
    set_page_counts(count)
    params[:sort] = 'dpn_created_at DESC' unless params[:sort]
    @dpn_bags = @dpn_bags.order(params[:sort])
  end

  def set_filter_values
    # Some kind of datepicker thing for completed_before / completed_after / etc
  end
end
