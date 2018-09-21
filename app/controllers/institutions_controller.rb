class InstitutionsController < ApplicationController
  inherit_resources
  before_action :authenticate_user!
  before_action :load_institution, only: [:edit, :update, :show, :destroy, :single_snapshot, :deactivate, :reactivate, 
                                          :trigger_bulk_delete, :partial_confirmation_bulk_delete, :final_confirmation_bulk_delete, 
                                          :finished_bulk_delete]
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

  def trigger_bulk_delete
    authorize @institution, :bulk_delete?
    build_bulk_deletion_list
    log = Email.log_deletion_request(@institution)
    ConfirmationToken.where(institution_id: @institution.id).delete_all # delete any old tokens. Only the new one should be valid
    token = ConfirmationToken.create(institution: @institution, token: SecureRandom.hex)
    token.save!
    NotificationMailer.bulk_deletion_inst_admin_approval(@institution, @final_ident_list, @forbidden_idents, current_user, log, token).deliver!
    respond_to do |format|
      format.json { head :no_content }
      format.html {
        redirect_to root_path
        flash[:notice] = 'An email has been sent to the administrators of this institution to confirm this bulk deletion request.'
      }
    end
  end

  def partial_confirmation_bulk_delete
    authorize @institution
    if params[:confirmation_token] == @institution.confirmation_token.token
      log = Email.log_bulk_deletion_confirmation(@institution, 'partial')
      ConfirmationToken.where(institution_id: @institution.id).delete_all # delete any old tokens. Only the new one should be valid
      token = ConfirmationToken.create(institution: @institution, token: SecureRandom.hex)
      token.save!
      NotificationMailer.bulk_deletion_apt_admin_approval(@institution, params[:ident_list], current_user.id, params[:requesting_user_id], log, token).deliver!
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Bulk delete job for: #{@institution.name} has been sent forward for final approval by an APTrust administrator."
          redirect_to root_path
        }
      end
    else
      respond_to do |format|
        message = 'Your bulk deletion event cannot be queued at this time due to an invalid confirmation token. ' +
            'Please contact your APTrust administrator for more information.'
        format.json {
          render :json => { status: 'error', message: message }, :status => :conflict
        }
        format.html {
          redirect_to institution_url(@institution)
          flash[:alert] = message
        }
      end
    end
  end

  def final_confirmation_bulk_delete
    authorize @institution
    if params[:confirmation_token] == @institution.confirmation_token.token
      confirmed_destroy
      log = Email.log_bulk_deletion_confirmation(@institution, 'final')
      NotificationMailer.bulk_deletion_queued(@institution, params[:ident_list], current_user.id, params[:inst_approver_id], params[:requesting_user_id], log).deliver!
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Bulk deletion request for #{@institution.name} has been queued."
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
          redirect_to root_path
          flash[:alert] = message
        }
      end
    end
  end

  def finished_bulk_delete
    authorize @institution
    bulk_mark_deleted
    log = Email.log_deletion_finished(@institution)
    NotificationMailer.bulk_deletion_finished(@institution, params[:ident_list], params[:apt_approver_id], params[:inst_approver_id], params[:requesting_user_id], log).deliver!
    respond_to do |format|
      format.json { head :no_content }
      format.html { 
        flash[:notice] = "Bulk deletion job for #{@institution.name} has been completed."
        redirect_to root_path
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

  def build_bulk_deletion_list
    @forbidden_idents = { }
    @final_ident_list = []
    initial_identifiers = params[:ident_list]
    initial_identifiers.each do |identifier|
      current = IntellectualObject.find_by_identifier(identifier)
      current = GenericFile.find_by_identifier(identifier) if current.nil?
      pending = WorkItem.pending_action(identifier)
      if current.state == 'D'
        @forbidden_idents[identifier] = 'This item has already been deleted.'
      elsif !pending.nil?
        @forbidden_idents[identifier] = "Your item cannot be deleted at this time due to a pending #{pending.action} request. You may delete this object after the #{pending.action} request has completed."
      else
        @final_ident_list.push(identifier)
      end
    end
  end

  def confirmed_destroy
    requesting_user = User.readable(current_user).find(params[:requesting_user_id])
    inst_approver = User.readable(current_user).find(params[:inst_approver_id])
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
    params[:ident_list].each do |identifier|
      io = IntellectualObject.with_identifier(identifier).first
      gf = GenericFile.with_identifier(identifier).first
      options = {inst_app: inst_approver.email, apt_app: current_user.email}
      io.soft_delete(attributes, options) unless io.nil?
      gf.soft_delete(attributes, options) unless gf.nil?
    end
  end

  def bulk_mark_deleted
    params[:ident_list].each do |identifier|
      io = IntellectualObject.with_identifier(identifier).first
      gf = GenericFile.with_identifier(identifier).first
      if io && WorkItem.deletion_finished?(io.identifier)
        io.state = 'D'
        io.save!
      end
      if gf && WorkItem.deletion_finished_for_file?(gf.identifier)
        gf.state = 'D'
        gf.save!
      end
    end
  end

end
