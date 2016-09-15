class InstitutionsController < ApplicationController
  include SearchAndIndex
  inherit_resources
  before_filter :authenticate_user!
  before_action :load_institution, only: [:edit, :update, :show, :destroy]
  respond_to :json, :html
  after_action :verify_authorized, :except => :index
  after_action :verify_policy_scoped, :only => :index

  def index
    respond_to do |format|
      @institutions = policy_scope(Institution)
      @sizes = find_all_sizes unless request.url.include?("/api/")
      @count = @institutions.count
      page_results(@institutions)
      format.json { render json: {count: @count, next: @next, previous: @previous, results: @institutions.map{ |item| item.serializable_hash }} }
      format.html { render 'index' }
    end
  end

  def new
    @institution = Institution.new
    authorize @institution
  end

  def create
    @institution = build_resource
    authorize @institution
    create!
  end

  def show
    authorize @institution || Institution.new
    if @institution.nil? || @institution.state == 'D'
      respond_to do |format|
        format.json {render :nothing => true, :status => 404}
        format.html {
          redirect_to root_path
          flash[:alert] = 'The institution you requested does not exist or has been deleted.'
        }
      end
    else
      set_recent_objects
      respond_to do |format|
        format.json { render json: @institution }
        format.html
      end
    end
  end

  def edit
    authorize @institution
    edit!
  end

  def update
    authorize @institution
    update!
  end

  private
  def load_institution
    @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(identifier: params[:institution_identifier]).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def build_resource_params
    params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :identifier, :brief_name, :dpn_uuid)]
  end

  def set_recent_objects
    if (current_user.admin? && current_user.institution.identifier == @institution.identifier)  ||
        (current_user.institutional_admin? && current_user.institution.name == 'APTrust' && current_user.institution.identifier == @institution.identifier)
      @items = WorkItem.order('date').limit(10).reverse_order
      @size = GenericFile.bytes_by_format['all']
      @item_count = WorkItem.all.count
      @object_count = IntellectualObject.all.count
    else
      @items = WorkItem.with_institution(@institution.id).order('date').limit(10).reverse_order
      @size = @institution.bytes_by_format()['all']
      @item_count = WorkItem.with_institution(@institution.id).count
      @object_count = @institution.intellectual_objects.count
    end
    @failed = @items.where(status: Pharos::Application::PHAROS_STATUSES['fail'])
  end

  def find_all_sizes
    size = {}
    total_size = 0
    Institution.all.each do |inst|
      size[inst.name] = inst.bytes_by_format()['all']
      total_size = size[inst.name] + total_size
    end
    size['APTrust'] = total_size
    size
  end

end
