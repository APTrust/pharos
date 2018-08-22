class InstitutionsController < ApplicationController
  inherit_resources
  before_action :authenticate_user!
  before_action :load_institution, only: [:edit, :update, :show, :destroy, :single_snapshot, :deactivate, :reactivate]
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

  def deactivate
    authorize @institution
    @institution.deactivate
    flash[:notice] = "All users at #{@institution.name} have been deactivated."
    respond_to do |format|
      format.html { render 'show' }
    end
  end

  def reactivate
    authorize @institution
    @institution.reactivate
    flash[:notice] = "All users at #{@institution.name} have been reactivated."
    respond_to do |format|
      format.html { render 'show' }
    end
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
    email_snap_hash = {}
    total_bytes = Institution.total_file_size_across_repo
    email_snap_hash['Repository Total'] = total_bytes
    MemberInstitution.all.order('name').each do |institution|
      current_snaps = institution.snapshot
      @snapshots.push(current_snaps)
      current_snaps.each do |snap|
        email_snap_hash[institution.name] = snap.apt_bytes if snap.snapshot_type == 'Subscribers Included'
      end
    end
    NotificationMailer.snapshot_notification(email_snap_hash).deliver!
    respond_to do |format|
      format.json { render json: { snapshots: @snapshots.each { |snap_set| snap_set.map { |item| item.serializable_hash } } } }
      format.html {
        redirect_to root_path
        flash[:notice] = "A snapshot of all Member Institutions has been taken and archived on #{@snapshots.first.first.audit_date}. Please see the reports page for that analysis."
      }
    end
  end

  def bulk_delete
    authorize @institution
    pending = WorkItem.pending_action(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      respond_to do |format|
        format.json { head :conflict }
        format.html {
          redirect_to @intellectual_object
          flash[:alert] = 'This item has already been deleted.'
        }
      end
    elsif pending.nil?
      log = Email.log_deletion_request(@intellectual_object)
      ConfirmationToken.where(intellectual_object_id: @intellectual_object.id).delete_all #delete any old tokens. Only the new one should be valid
      token = ConfirmationToken.create(intellectual_object: @intellectual_object, token: SecureRandom.hex)
      token.save!
      NotificationMailer.deletion_request(@intellectual_object, current_user, log, token).deliver!
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          redirect_to @intellectual_object
          flash[:notice] = 'An email has been sent to the administrators of this institution to confirm deletion of this object.'
        }
      end
    else
      respond_to do |format|
        message = "Your object cannot be deleted at this time due to a pending #{pending.action} request. " +
            "You may delete this object after the #{pending.action} request has completed."
        format.json {
          render :json => { status: 'error', message: message }, :status => :conflict
        }
        format.html {
          redirect_to @intellectual_object
          flash[:alert] = message
        }
      end
    end
  end

  def confirm_bulk_delete_aptrust_admin
    authorize @institution
    if params[:confirmation_token] == @institution.confirmation_token.token
      log = Email.log_deletion_request(@institution)
      ConfirmationToken.where(intellectual_object_id: @intellectual_object.id).delete_all #delete any old tokens. Only the new one should be valid
      token = ConfirmationToken.create(intellectual_object: @intellectual_object, token: SecureRandom.hex)
      token.save!
      NotificationMailer.deletion_request(@intellectual_object, current_user, log, token).deliver!
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Deletion request has been forwarded to an institutional administrator at #{@institution.name} for final confirmation."
          redirect_to root_path
        }
      end
    else
      respond_to do |format|
        message = 'This bulk deletion request cannot be completed at this time due to an invalid confirmation token. ' +
            'Please contact your APTrust administrator for more information.'
        format.json {
          render :json => { status: 'error', message: message }, :status => :conflict
        }
        format.html {
          redirect_to @institution
          flash[:alert] = message
        }
      end
    end
  end

  def confirm_bulk_delete_inst_admin
    authorize @institution
    if params[:confirmation_token] == @intellectual_object.confirmation_token.token
      confirmed_destroy
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been queued for object: #{@intellectual_object.title}. Depending on the size of the object, it may take a few minutes for all associated files to be marked as deleted."
          redirect_to root_path
        }
      end
    else
      respond_to do |format|
        message = 'Your object cannot be deleted at this time due to an invalid confirmation token. ' +
            'Please contact your APTrust administrator for more information.'
        format.json {
          render :json => { status: 'error', message: message }, :status => :conflict
        }
        format.html {
          redirect_to @intellectual_object
          flash[:alert] = message
        }
      end
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

    def confirmed_destroy
    requesting_user = User.readable(current_user).find(params[:requesting_user_id])
    attributes = { event_type: Pharos::Application::PHAROS_EVENT_TYPES['delete'],
                   date_time: "#{Time.now}",
                   detail: 'Object deleted from S3 storage',
                   outcome: 'Success',
                   outcome_detail: requesting_user.email,
                   object: 'Goamz S3 Client',
                   agent: 'https://github.com/crowdmob/goamz',
                   outcome_information: "Action requested by user from #{requesting_user.institution_id}",
                   identifier: SecureRandom.uuid
    }
    @intellectual_object.soft_delete(attributes)
    log = Email.log_deletion_confirmation(@intellectual_object)
    NotificationMailer.deletion_confirmation(@intellectual_object, requesting_user, log).deliver!
  end

end
