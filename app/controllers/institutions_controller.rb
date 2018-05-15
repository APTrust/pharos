class InstitutionsController < ApplicationController
  require 'google_drive'
  inherit_resources
  before_action :authenticate_user!
  before_action :load_institution, only: [:edit, :update, :show, :destroy, :single_snapshot]
  respond_to :json, :html
  after_action :verify_authorized, :except => :index
  after_action :verify_policy_scoped, :only => :index

  def index
    respond_to do |format|
      @institutions = policy_scope(Institution)
      @institutions = @institutions.order('name')
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
        format.json {render body: nil, :status => 404}
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

  def destroy
    authorize current_user, :delete_institution?
    destroy!
  end

  def single_snapshot
    authorize @institution, :snapshot?
    if @institution.is_a?(MemberInstitution)
      @snapshots = @institution.snapshot
      respond_to do |format|
        format.json { render json: { institution: @institution.name, snapshots: @snapshots.map{ |item| item.serializable_hash } } }
        format.html {
          redirect_to root_path
          flash[:notice] = "A snapshot of #{@institution.name} has been taken and archived on #{@snapshots.first.audit_date}. Please see the reports page for that analysis."
        }
      end
    else
      @snapshot = @institution.snapshot
      respond_to do |format|
        format.json { render json: { institution: @institution.name, snapshot: @snapshot.serializable_hash }  }
        format.html {
          redirect_to root_path
          flash[:notice] = "A snapshot of #{@institution.name} has been taken and archived on #{@snapshot.audit_date}. Please see the reports page for that analysis."
        }
      end
    end
  end

  def group_snapshot
    authorize current_user, :snapshot?
    @snapshots = []
    @wb_hash = {}
    @date_str = Time.now.utc.strftime('%m/%d/%Y')
    total_size = Institution.total_file_size_across_repo
    @wb_hash['Repository Total'] = total_size
    MemberInstitution.all.order('name').each do |institution|
      current_snaps = institution.snapshot
      @snapshots.push(current_snaps)
      current_snaps.each do |snap|
        @wb_hash[institution.name] = snap.apt_bytes if snap.snapshot_type == 'Subscribers Included'
      end
    end
    # Snapshot.where("created_at > '2018-05-07 16:38:41.402948' AND snapshot_type = 'Subscribers Included'").each do |snap|
    #   inst = Institution.find(snap.institution_id)
    #   @wb_hash[inst.name] = snap.apt_bytes
    # end
    NotificationMailer.snapshot_notification(@wb_hash).deliver!
    write_snapshots_to_spreadsheet if Rails.env.production?
    respond_to do |format|
      format.json { render json: { snapshots: @snapshots.each { |snap_set| snap_set.map { |item| item.serializable_hash } } } }
      format.html {
        redirect_to root_path
        flash[:notice] = "A snapshot of all Member Institutions has been taken and archived on #{@snapshots.first.first.audit_date}. Please see the reports page for that analysis."
      }
    end
  end

  private
  def load_institution
    @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(identifier: params[:institution_identifier]).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def build_resource_params
    params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :identifier, :brief_name, :dpn_uuid, :type, :member_institution_id)]
  end

  def set_recent_objects
    if (current_user.admin? && current_user.institution.identifier == @institution.identifier)  ||
        (current_user.institutional_admin? && current_user.institution.name == 'APTrust' && current_user.institution.identifier == @institution.identifier)
      @items = WorkItem.limit(10).order('date').reverse_order
      @size = Institution.total_file_size_across_repo
      @item_count = WorkItem.all.count
      @object_count = IntellectualObject.with_state('A').size
    else
      items = WorkItem.with_institution(@institution.id)
      @items = items.limit(10).order('date').reverse_order
      @size = @institution.total_file_size
      @item_count = items.size
      @object_count = @institution.intellectual_objects.with_state('A').size
    end
  end

  def find_all_sizes
    size = {}
    total_size = 0
    Institution.all.each do |inst|
      size[inst.name] = inst.total_file_size
      size[inst.name] = 0 if size[inst.name].nil?
      total_size += size[inst.name]
    end
    size['APTrust'] = total_size
    size
  end

  def set_attachment_name(name)
    escaped = URI.encode(name)
    response.headers['Content-Disposition'] = "attachment; filename*=UTF-8''#{escaped}"
  end

  def write_snapshots_to_spreadsheet
    session = GoogleDrive::Session.from_config('config.json')
    # sheet = session.spreadsheet_by_key('1E29ttbnuRDyvWfYAh6_-Zn9s0ChOspUKCOOoeez1fZE').worksheets[0] # Chip Sheet
    sheet = session.spreadsheet_by_key('1T_zlgluaGdEU_3Fm06h0ws_U4mONpDL4JLNP_z-CU20').worksheets[0] # Kelly Test Sheet
    date_column = 0
    counter = 2
    while date_column == 0 && counter < 100
      cell = sheet[3, counter]
      converted_date = Date.strptime(cell, '%m/%d/%Y').strftime('%m/%d/%Y')
      date_column = counter if converted_date == @date_str unless cell.nil?
      counter += 1
    end
    i = 1
    unless date_column == 0
      while i < 200
        cell = sheet[i, 1]
        unless cell.nil?
          if @wb_hash.has_key?(cell)
            gb = (@wb_hash[cell].to_f / 1073741824).round(2)
            sheet[(i+1), date_column] = gb
          end
        end
        i += 1
      end
    end
    sheet.save
  end

end
