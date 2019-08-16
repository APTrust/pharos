class InstitutionsController < ApplicationController
  require 'google_drive'
  inherit_resources
  skip_before_action :verify_authenticity_token, only: [:trigger_bulk_delete]
  before_action :authenticate_user!
  before_action :load_institution, only: [:edit, :update, :show, :destroy, :single_snapshot, :deactivate, :reactivate,
                                          :trigger_bulk_delete, :partial_confirmation_bulk_delete, :final_confirmation_bulk_delete,
                                          :finished_bulk_delete, :enable_otp, :disable_otp, :mass_forced_password_update]
  respond_to :json, :html
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

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

  def mass_forced_password_update
    authorize @institution
    @users = @institution.users
    @users.each do |usr|
      usr.force_password_update = true unless usr.id == current_user.id
      usr.save!
    end
    msg = "All users at #{@institution.name} will be forced to change their password upon next login. If you forced password "+
        'changes at your own institution, you will not be forced to change your own password but it is highly encouraged.'
    respond_to do |format|
      format.json { render json: { message: msg }, status: :ok }
      format.html { redirect_to institution_path(@institution), flash: { notice: msg } }
    end
  end

  def enable_otp
    authorize @institution
    @institution.otp_enabled = true
    @institution.save!
    msg = "Two Factor Authentication is now required for all users at #{@institution.name}."
    flash[:notice] = msg
    respond_to do |format|
      format.json { render json: { message: msg }, status: :ok }
      format.html { render 'show' }
    end
  end

  def disable_otp
    authorize @institution
    @institution.otp_enabled = false
    @institution.save!
    msg = "Two Factor Authentication is no longer required for institutional users at #{@institution.name}"
    flash[:notice] = msg
    respond_to do |format|
      format.json { render json: { message: msg }, status: :ok }
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
    @wb_hash = {}
    @date_str = Time.now.utc.strftime('%m/%d/%Y')
    @wb_hash['Repository Total'] = Institution.total_file_size_across_repo
    MemberInstitution.all.order('name').each do |institution|
      current_snaps = institution.snapshot
      @snapshots.push(current_snaps)
      current_snaps.each do |snap|
        if snap.snapshot_type == 'Individual'
          current_inst = Institution.find(snap.institution_id)
          @wb_hash[current_inst.name] = [snap.cs_bytes, snap.go_bytes]
        end
      end
    end
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

  def trigger_bulk_delete
    authorize @institution, :bulk_delete?
    @bulk_job = BulkDeleteJob.create(requested_by: current_user.email, institution_id: @institution.id)
    @bulk_job.save!
    parse_ident_list
    build_bulk_deletion_list
    csv = @institution.generate_confirmation_csv(@bulk_job)
    log = Email.log_deletion_request(@institution)
    ConfirmationToken.where(institution_id: @institution.id).delete_all # delete any old tokens. Only the new one should be valid
    token = ConfirmationToken.create(institution: @institution, token: SecureRandom.hex)
    token.save!
    NotificationMailer.bulk_deletion_inst_admin_approval(@institution, @bulk_job, @forbidden_idents, log, token, csv).deliver!
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
    @bulk_job = BulkDeleteJob.find(params[:bulk_delete_job_id])
    if !@institution.confirmation_token.nil? && params[:confirmation_token] == @institution.confirmation_token.token
      if @bulk_job.institutional_approver.nil?
        @bulk_job.institutional_approver = current_user.email
        @bulk_job.institutional_approval_at = Time.now.utc
        @bulk_job.save!
        log = Email.log_bulk_deletion_confirmation(@institution, 'partial')
        csv = @institution.generate_confirmation_csv(@bulk_job)
        ConfirmationToken.where(institution_id: @institution.id).delete_all # delete any old tokens. Only the new one should be valid
        token = ConfirmationToken.create(institution: @institution, token: SecureRandom.hex)
        token.save!
        NotificationMailer.bulk_deletion_apt_admin_approval(@institution, @bulk_job, log, token, csv).deliver!
        respond_to do |format|
          format.json { head :no_content }
          format.html {
            flash[:notice] = "Bulk delete job for: #{@institution.name} has been sent forward for final approval by an APTrust administrator."
            redirect_to root_path
          }
        end
      else
        respond_to do |format|
          message = 'This bulk deletion request has already been confirmed and sent forward for APTrust approval by someone else.'
          format.json {
            render :json => { status: 'ok', message: message }, :status => :ok
          }
          format.html {
            redirect_to root_path
            flash[:notice] = message
          }
        end
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
    @bulk_job = BulkDeleteJob.find(params[:bulk_delete_job_id])
    if @institution.confirmation_token.nil? && !@bulk_job.aptrust_approver.nil?
      respond_to do |format|
        message = 'This bulk deletion request has already been confirmed and queued for deletion by someone else.'
        format.json {
          render :json => { status: 'ok', message: message }, :status => :ok
        }
        format.html {
          redirect_to root_path
          flash[:notice] = message
        }
      end
    else
      if params[:confirmation_token] == @institution.confirmation_token.token
        @bulk_job.aptrust_approver = current_user.email
        @bulk_job.aptrust_approval_at = Time.now.utc
        @bulk_job.save!
        confirmed_destroy
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
  end

  def finished_bulk_delete
    authorize @institution
    @bulk_job = BulkDeleteJob.find(params[:bulk_delete_job_id])
    bulk_mark_deleted
    log = Email.log_deletion_finished(@institution)
    csv = @institution.generate_confirmation_csv(@bulk_job)
    NotificationMailer.bulk_deletion_finished(@institution, @bulk_job, log, csv).deliver!
    respond_to do |format|
      format.json { head :no_content }
      format.html {
        flash[:notice] = "Bulk deletion job for #{@institution.name} has been completed."
        redirect_to root_path
      }
    end
  end

  def deletion_notifications
    authorize current_user, :deletion_notifications?
    Institution.all.each do |current_inst|
      items = current_inst.new_deletion_items
      unless items.nil? || items.count == 0
        current_inst.generate_deletion_zipped_csv(items)
        email = NotificationMailer.deletion_notification(current_inst).deliver_now
        email_log = Email.log_daily_deletion_notification(current_inst)
        email_log.user_list = email.to
        email_log.email_text = email.body.encoded
        email_log.save!
      end
    end
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to root_path }
    end
  end

  private

  def load_institution
    @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(identifier: params[:institution_identifier]).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def build_resource_params
    params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :identifier, :dpn_uuid, :type, :member_institution_id)]
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
    initial_identifiers = @ident_list
    initial_identifiers.each do |identifier|
      current = IntellectualObject.find_by_identifier(identifier)
      current = GenericFile.find_by_identifier(identifier) if current.nil?
      pending = WorkItem.pending_action(identifier)
      if current.state == 'D'
        @forbidden_idents[identifier] = 'This item has already been deleted.'
      elsif !pending.nil?
        @forbidden_idents[identifier] = "Your item cannot be deleted at this time due to a pending #{pending.action} request. You may delete this object after the #{pending.action} request has completed."
      else
        current.is_a?(IntellectualObject) ? @bulk_job.intellectual_objects.push(current) : @bulk_job.generic_files.push(current)
      end
    end
  end

  def confirmed_destroy
    requesting_user = User.readable(current_user).where(email: @bulk_job.requested_by).first
    attributes = { requestor: requesting_user.email,
                   inst_app: @bulk_job.institutional_approver,
                   apt_app: @bulk_job.aptrust_approver
    }
    @t = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ConfirmationToken.where(institution_id: @institution.id).delete_all # delete any old tokens
        @bulk_job.intellectual_objects.each do |obj|
          begin
            obj.soft_delete(attributes)
          rescue => e
            logger.error "Exception in Bulk Delete. Object Identifier: #{obj.identifier}"
            logger.error e.message
            logger.error e.backtrace.join("\n")
          end
        end
        @bulk_job.generic_files.each do |file|
          begin
            file.soft_delete(attributes)
          rescue => e
            logger.error "Exception in Bulk Delete. Object Identifier: #{file.identifier}"
            logger.error e.message
            logger.error e.backtrace.join("\n")
          end
        end
        log = Email.log_bulk_deletion_confirmation(@institution, 'final')
        csv = @institution.generate_confirmation_csv(@bulk_job)
        NotificationMailer.bulk_deletion_queued(@institution, @bulk_job, log, csv).deliver!
      end
      ActiveRecord::Base.connection_pool.release_connection
    end
    #t.join
  end

  def bulk_mark_deleted
    @bulk_job.intellectual_objects.each do |obj|
      if WorkItem.deletion_finished?(obj.identifier)
        attributes = { event_type: Pharos::Application::PHAROS_EVENT_TYPES['delete'],
                       date_time: "#{Time.now}",
                       detail: 'Object deleted from S3 storage',
                       outcome: 'Success',
                       outcome_detail: @bulk_job.requested_by,
                       object: 'AWS Go SDK S3 Library',
                       agent: 'https://github.com/aws/aws-sdk-go',
                       identifier: SecureRandom.uuid,
                       outcome_information: "Object deleted as part of bulk deletion at the request of #{@bulk_job.requested_by}. Institutional Approver: #{@bulk_job.institutional_approver}. APTrust Approver: #{@bulk_job.aptrust_approver}"

        }
        obj.mark_deleted(attributes)
      end
    end

    @bulk_job.generic_files.each do |file|
      if WorkItem.deletion_finished_for_file?(file.identifier)
        file.state = 'D'
        file.save!
      end
    end
  end

  def parse_ident_list
    begin
      list = JSON.parse(request.body.read)
    rescue JSON::ParserError, Exception => e
      respond_to do |format|
        format.json { render json: {error: "JSON parse error: #{e.message}"}, status: 400 } and return
      end
    end
    if list
      @ident_list = list['ident_list']
    end
  end

  def set_attachment_name(name)
    escaped = URI.encode(name)
    response.headers['Content-Disposition'] = "attachment; filename*=UTF-8''#{escaped}"
  end

  def write_snapshots_to_spreadsheet
    session = GoogleDrive::Session.from_config('config.json')
    sheet = session.spreadsheet_by_key('1E29ttbnuRDyvWfYAh6_-Zn9s0ChOspUKCOOoeez1fZE').worksheets[0] # Chip Sheet
    # sheet = session.spreadsheet_by_key('1T_zlgluaGdEU_3Fm06h0ws_U4mONpDL4JLNP_z-CU20').worksheets[0] # Kelly Test Sheet
    date_column = 0
    counter = 2
    while date_column == 0
      cell = sheet[3, counter]
      date_column = counter if cell.nil? || cell.empty? || cell == ''
      counter += 1
    end
    i = 1
    unless date_column == 0
      sheet[3, date_column] = @date_str
      while i < 2000
        cell = sheet[i, 1]
        unless cell.nil?
          if @wb_hash.has_key?(cell)
            cs_gb = (@wb_hash[cell][0].to_f / 1073741824).round(2)
            go_gb = (@wb_hash[cell][1].to_f / 1073741824).round(2)
            column = to_s26(date_column)
            previous_column = to_s26(date_column - 1)
            sheet[(i+1), date_column] = cs_gb
            sheet[(i+2), date_column] = "=#{column}#{i+1}/1024"
            sheet[(i+3), date_column] = "=#{column}#{i+2}-#{previous_column}#{i+2}"
            sheet[(i+4), date_column] = "=#{column}#{i+2}-10"
            sheet[(i+5), date_column] = go_gb
            sheet[(i+6), date_column] = "=#{column}#{i+5}/1024"
            sheet[(i+7), date_column] = "=#{column}#{i+6}-#{previous_column}#{i+6}"
            sheet[(i+8), date_column] = "=((#{column}#{i+4}*#{column}$195)+((#{column}#{i+4}*#{column}$195)<0)*abs((#{column}#{i+4}*#{column}$195)))+(#{column}#{i+6}*#{column}$196)"
          end
        end
        i += 1
      end
    end
    sheet.save
  end

  Alpha26 = ("a".."z").to_a

  def to_s26(number)
    return "" if number < 1
    s, q = "", number
    loop do
      q, r = (q - 1).divmod(26)
      s.prepend(Alpha26[r])
      break if q.zero?
    end
    s
  end

end
