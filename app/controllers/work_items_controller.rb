class WorkItemsController < ApplicationController
  include FilterCounts
  require 'uri'
  require 'net/http'
  respond_to :html, :json
  before_action :authenticate_user!
  before_action :set_item, only: [:show, :requeue, :spot_test_restoration]
  before_action :init_from_params, only: :create
  before_action :load_institution, only: :index
  #after_action :check_for_completed_restoration, only: :update
  after_action :verify_authorized

  def index
    (current_user.admin? and params[:institution].present?) ? @items = WorkItem.with_institution(params[:institution]) : @items = WorkItem.readable(current_user)
    filter_count_and_sort
    page_results(@items)
    if @items.nil? || @items.empty?
      authorize current_user, :nil_index?
      respond_to do |format|
        format.json {
          json_list = @paged_results.map { |item| item.serializable_hash(except: [:node, :pid]) }
          render json: {count: @count, next: @next, previous: @previous, results: json_list}
        }
        format.html { render 'old_index' }
      end
    else
      authorize @items
      respond_to do |format|
        format.json {
          if current_user.admin?
            json_list = @paged_results.map { |item| item.serializable_hash }
          else
            json_list = @paged_results.map { |item| item.serializable_hash(except: [:node, :pid]) }
          end
          render json: {count: @count, next: @next, previous: @previous, results: json_list}
        }
        format.html { render 'old_index' }
      end
    end
  end

  def create
    authorize @work_item
    respond_to do |format|
      if @work_item.save
        format.json { render json: @work_item, status: :created }
      else
        format.json { render json: @work_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    if @work_item
      authorize @work_item
      (params[:with_state_json] == 'true' && current_user.admin?) ? @show_state = true : @show_state = false
      respond_to do |format|
        if current_user.admin?
          format.json { render json: @work_item.serializable_hash }
        else
          format.json { render json: @work_item.serializable_hash(except: [:node, :pid]) }
        end
        format.html
      end
    else
      authorize current_user, :nil_index?
      respond_to do |format|
        format.json { render body: nil, status: :not_found }
        format.html { redirect_to root_url, alert: 'That Work Item could not be found.' }
      end
    end
  end

  def requeue
    if @work_item
      authorize @work_item
      if @work_item.status == Pharos::Application::PHAROS_STATUSES['success']
        respond_to do |format|
          format.json { render :json => { status: 'error', message: 'Work Items that have succeeded cannot be requeued.' }, :status => :conflict }
          format.html { }
        end
      else
        options = {}
        options[:stage] = params[:item_stage] if params[:item_stage]
        options[:work_item_state_delete] = 'true' if params[:delete_state_item] && params[:delete_state_item] == 'true'
        @work_item.requeue_item(options)
        if Rails.env.development?
          flash[:notice] = 'The response from NSQ to the requeue request is as follows: Status: 200, Body: ok'
          flash.keep(:notice)
          respond_to do |format|
            format.json { render json: { status: 200, body: 'ok' } }
            format.html {
              redirect_to work_item_path(@work_item.id)
              flash[:notice] = 'The response from NSQ to the requeue request is as follows: Status: 200, Body: ok'
            }
          end
        else
          options[:stage] ? response = issue_requeue_http_post(options[:stage]) : response = issue_requeue_http_post('')
          respond_to do |format|
            format.json { render json: { status: response.code, body: response.body } }
            format.html {
              redirect_to work_item_path(@work_item.id)
              flash[:notice] = "The response from NSQ to the requeue request is as follows: Status: #{response.code}, Body: #{response.body}"
            }
          end
        end
      end
    else
      authorize current_user, :nil_index?
      respond_to do |format|
        format.json { render nothing: true, status: :not_found }
        format.html { redirect_to root_url, alert: 'That Work Item could not be found.' }
      end
    end
  end

  # Note that this method is available through the admin API, but is
  # not accessible to members. If we ever make it accessible to members,
  # we MUST NOT allow them to update :state, :node, or :pid!
  def update
    if params[:save_batch]
      authorize current_user, :work_item_batch_update?
      WorkItem.transaction do
        batch_work_item_update_params
        @work_items = []
        params[:work_items][:items].each do |current|
          wi = WorkItem.find(current['id'])
          wi.update(current)
          # Only admin can explicitly set user.
          if !current_user.admin? || wi.user.blank?
            wi.user = current_user.email
          end
          @work_items.push(wi)
          unless wi.save
            @incomplete = true
            break
          end
        end
        raise ActiveRecord::Rollback
      end
      respond_to do |format|
        if @incomplete
          errors = @work_items.map(&:errors)
          format.json { render json: errors, status: :unprocessable_entity }
        else
          format.json { render json: array_as_json(@work_items), status: :ok }
        end
      end
    else
      find_and_update
      authorize @work_item
      respond_to do |format|
        if @work_item.save
          format.json { render json: @work_item, status: :ok }
        else
          format.json { render json: @work_item.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def ingested_since
    since = params[:since]
    begin
      dtSince = DateTime.parse(since)
    rescue
      # We'll get this below
    end
    respond_to do |format|
      if dtSince == nil
        authorize WorkItem.new, :admin_api?
        err = { 'error' => 'Param since must be a valid datetime' }
        format.json { render json: err, status: :bad_request }
      else
        @items = WorkItem.where("action='Ingest' and date >= ?", dtSince)
        authorize @items, :admin_api?
        format.json { render json: @items, status: :ok }
      end
    end
  end

  def set_restoration_status
    # Fix Apache/Passenger passthrough of %2f-encoded slashes in identifier
    params[:object_identifier] = params[:object_identifier].gsub(/%2F/i, "/")
    params[:node] = nil if params[:node] && params[:node] == ''
    restore = Pharos::Application::PHAROS_ACTIONS['restore']
    @item = WorkItem.where(object_identifier: params[:object_identifier],
                           action: restore).order(created_at: :desc).first
    if @item.nil?
      authorize current_user
      render body: nil, status: :not_found and return
    else
      authorize @item
    end
    if @item
      succeeded = @item.update_attributes(params_for_status_update)
    end
    respond_to do |format|
      if @item.nil?
        error = { error: "No items for object identifier #{params[:object_identifier]}" }
        format.json { render json: error, status: :not_found }
      end
      if succeeded == false
        errors = @item.errors.full_messages
        format.json { render json: errors, status: :bad_request }
      else
        format.json { render json: {result: 'OK'}, status: :ok }
      end
    end
  end

  def items_for_restore
    restore = Pharos::Application::PHAROS_ACTIONS['restore']
    requested = Pharos::Application::PHAROS_STAGES['requested']
    pending = Pharos::Application::PHAROS_STATUSES['pend']
    @items = WorkItem.with_action(restore)
    @items = @items.with_institution(current_user.institution_id) unless current_user.admin?
    authorize @items
    # Get items for a single object, which may consist of multiple bags.
    # Return anything for that object identifier with action=Restore and retry=true
    if !request[:object_identifier].blank?
      @items = @items.with_object_identifier(request[:object_identifier])
    else
      # If user is not looking for a single bag, return all requested/pending items.
      @items = @items.where(stage: requested, status: pending, retry: true)
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end

  def items_for_dpn
    dpn = Pharos::Application::PHAROS_ACTIONS['dpn']
    requested = Pharos::Application::PHAROS_STAGES['requested']
    pending = Pharos::Application::PHAROS_STATUSES['pend']
    @items = WorkItem.with_action(dpn)
    @items = @items.with_institution(current_user.institution_id) unless current_user.admin?
    authorize @items
    # Get items for a single object, which may consist of multiple bags.
    # Return anything for that object identifier with action=DPN and retry=true
    if !request[:object_identifier].blank?
      @items = @items.with_object_identifier(request[:object_identifier])
    else
       # If user is not looking for a single bag, return all requested/pending items.
       @items = @items.where(stage: requested, status: pending, retry: true)
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end

  def items_for_delete
    delete = Pharos::Application::PHAROS_ACTIONS['delete']
    requested = Pharos::Application::PHAROS_STAGES['requested']
    pending = Pharos::Application::PHAROS_STATUSES['pend']
    failed = Pharos::Application::PHAROS_STATUSES['fail']
    @items = WorkItem.with_action(delete)
    @items = @items.with_institution(current_user.institution_id) unless current_user.admin?
    authorize @items
    # Return a record for a single file?
    if !request[:generic_file_identifier].blank?
      @items = @items.with_file_identifier(request[:generic_file_identifier])
    else
      # If user is not looking for a single bag, return all requested items
      # where retry is true and status is pending or failed.
      @items = @items.where(stage: requested, status: [pending, failed], retry: true)
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end

  def notify_of_successful_restoration
    authorize current_user
    params[:since] = (DateTime.now - 24.hours) unless params[:since]
    @items = WorkItem.with_action(Pharos::Application::PHAROS_ACTIONS['restore'])
                     .with_status(Pharos::Application::PHAROS_STATUSES['success'])
                     .with_stage(Pharos::Application::PHAROS_STAGES['record'])
                     .updated_after(params[:since])
    institutions = @items.distinct.pluck(:institution_id)
    number_of_emails = 0
    inst_list = []
    institutions.each do |inst|
      inst_items = @items.where(institution_id: inst)
      institution = Institution.find(inst)
      log = Email.log_multiple_restoration(inst_items)
      NotificationMailer.multiple_restoration_notification(@items, log, institution).deliver!
      number_of_emails = number_of_emails + 1
      inst_list.push(institution.name)
    end
    if number_of_emails == 0
      respond_to do |format|
        format.json { render json: { message: 'No new successful restorations, no emails sent.' }, status: 204 }
      end
    else
      inst_pretty = inst_list.join(', ')
      respond_to do |format|
        format.json { render json: { message: "#{number_of_emails} sent. Institutions that received a successful restoration notification: #{inst_pretty}." }, status: 200 }
      end
    end
  end

  def spot_test_restoration
    authorize current_user
    log = Email.log_restoration(@work_item.id)
    NotificationMailer.spot_test_restoration_notification(@work_item, log).deliver!
    respond_to do |format|
      format.json { render json: { message: "Admin users at #{@work_item.institution.name} have recieved a spot test restoration email for #{@work_item.object_identifier}" }, status: 200 }
    end
  end

  def api_search
    authorize WorkItem, :admin_api?
    current_user.admin? ? @items = WorkItem.all : @items = WorkItem.with_institution(current_user.institution_id)
    # if  Rails.env.development?
    #   rewrite_params_for_sqlite
    # end
    search_fields = [:name, :etag, :bag_date, :stage, :status, :institution,
                     :retry, :object_identifier, :generic_file_identifier,
                     :node, :needs_admin_review, :process_after]
    params[:retry] = to_boolean(params[:retry]) if params[:retry]
    params[:needs_admin_review] = to_boolean(params[:needs_admin_review]) if params[:needs_admin_review]
    search_fields.each do |field|
      if params[field].present?
        # if field == :bag_date && Rails.env.development?
        #   #@items = @items.where('datetime(bag_date) = datetime(?)', params[:bag_date])
        #   bag_date1 = DateTime.parse(params[:bag_date]) if params[:bag_date]
        #   bag_date2 = DateTime.parse(params[:bag_date]) + 1.seconds if params[:bag_date]
        #   @items = @items.with_bag_date(bag_date1, bag_date2)
        if field == :node and params[field] == 'null'
          @items = @items.where('node is null')
        elsif field == :assignment_pending_since and params[field] == 'null'
          @items = @items.where('assignment_pending_since is null')
        elsif field == :institution
          @items = @items.with_institution(params[field])
        else
          @items = @items.where(field => params[field])
        end
      end
    end

    if params[:item_action].present?
      @items = @items.with_action(params[:item_action])
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end

  private

  def load_institution
    (current_user.admin? and params[:institution].present?) ? @institution = Institution.find(params[:institution]) : @institution = current_user.institution
  end

  def array_as_json(list_of_work_items)
    list_of_work_items.map { |item| item.serializable_hash }
  end

  def init_from_params
    @work_item = WorkItem.new(writable_work_item_params)
    # When we're migrating data from Fluctus, we're
    # connecting as admin, and we want to preserve the existing
    # user attribute from the old system. In all other cases,
    # when we create a WorkItem, user should be set to the
    # current logged-in user.
    if !current_user.admin? || @work_item.user.blank?
      @work_item.user = current_user.email
    end
  end

  def find_and_update
    # Parse date explicitly, or ActiveRecord will not find records when date format string varies.
    set_item
    if @work_item
      @work_item.update(writable_work_item_params)
      # Never let non-admin set WorkItem.user.
      # Admin sets user only when importing WorkItems from Fluctus.
      if !current_user.admin? || @work_item.user.blank?
        @work_item.user = current_user.email
      end
    end
  end

  # Changed from the default "work_item_params" because Rails was
  # enforcing these on GET requests to the API and complaining
  # that "work_item: {}" was empty in requests that only used
  # a query string.
  def writable_work_item_params
    params.require(:work_item).permit(:name, :etag, :bag_date, :bucket,
                                      :institution_id, :date, :note, :action,
                                      :stage, :status, :outcome, :retry,
                                      :pid, :node, :object_identifier, :user,
                                      :generic_file_identifier, :needs_admin_review,
                                      :queued_at, :size, :stage_started_at)
  end

  def batch_work_item_update_params
    params[:work_items] &&= params.require(:work_items)
                                   .permit(items: [:name, :etag, :bag_date, :bucket,
                                                   :institution_id, :date, :note, :action,
                                                   :stage, :status, :outcome, :retry,
                                                   :node, :size, :stage_started_at, :id])
  end

  def params_for_status_update
    params.permit(:object_identifier, :stage, :status, :note, :retry,
                  :node, :pid, :needs_admin_review)
  end

  def set_item
    @institution = current_user.institution
    if params[:id].blank? == false
      begin
        @work_item = WorkItem.readable(current_user).find(params[:id])
      rescue
        # If we don't catch this, we get an internal server error
      end
    else
        @work_item = WorkItem.where(etag: params[:etag],
                                    name: params[:name],
                                    bag_date: params[:bag_date]).first
    end
  end

  # def rewrite_params_for_sqlite
  #   # SQLite wants t or f for booleans
  #   if params[:retry].present? && params[:retry].is_a?(String)
  #     params[:retry] = params[:retry][0]
  #   end
  # end

  def issue_requeue_http_post(stage)
    if @work_item.action == Pharos::Application::PHAROS_ACTIONS['delete']
      uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_file_delete_topic")
    elsif @work_item.action == Pharos::Application::PHAROS_ACTIONS['restore']
      if @work_item.generic_file_identifier.blank?
        # Restore full bag
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_restore_topic")
      else
        # Restore individual file. If it's in Glacier, we'll have to run
        # GlacierRestore first.
        gf = GenericFile.find_by_identifier(@work_item.generic_file_identifier)
        if gf && gf.storage_option == 'Standard'
          uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_file_restore_topic")
        else
          uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_glacier_restore_init_topic")
        end
      end
    elsif @work_item.action == Pharos::Application::PHAROS_ACTIONS['ingest']
      if stage == Pharos::Application::PHAROS_STAGES['fetch']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_fetch_topic")
      elsif stage == Pharos::Application::PHAROS_STAGES['store']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_store_topic")
      elsif stage == Pharos::Application::PHAROS_STAGES['record']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_record_topic")
      end
    elsif @work_item.action == Pharos::Application::PHAROS_ACTIONS['dpn']
      if stage == Pharos::Application::PHAROS_STAGES['package']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_package_topic")
      elsif stage == Pharos::Application::PHAROS_STAGES['store']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_ingest_store_topic")
      elsif stage == Pharos::Application::PHAROS_STAGES['record']
        uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=dpn_record_topic")
      end
    elsif @work_item.action == Pharos::Application::PHAROS_ACTIONS['glacier_restore']
      uri = URI("#{Pharos::Application::NSQ_BASE_URL}/pub?topic=apt_glacier_restore_init_topic")
    end
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request.body = @work_item.id.to_s
    http.request(request)
  end

  def filter_count_and_sort
    bag_date1 = DateTime.parse(params[:bag_date]) if params[:bag_date]
    bag_date2 = DateTime.parse(params[:bag_date]) + 1.seconds if params[:bag_date]
    date = format_date if params[:updated_since].present?
    @items = @items
                 .created_before(params[:created_before])
                 .created_after(params[:created_after])
                 .updated_before(params[:updated_before])
                 .updated_after(params[:updated_after])
                 .updated_after(date)
                 .with_bag_date(bag_date1, bag_date2)
                 .with_name(params[:name_exact])
                 .with_name(params[:name])
                 .with_name_like(params[:name_contains])
                 .with_name_like(params[:name_contains])
                 .with_etag(params[:etag])
                 .with_etag_like(params[:etag_contains])
                 .with_object_identifier(params[:object_identifier])
                 .with_object_identifier_like(params[:object_identifier_contains])
                 .with_file_identifier(params[:file_identifier])
                 .with_file_identifier_like(params[:file_identifier_contains])
                 .with_status(params[:status])
                 .with_stage(params[:stage])
                 .with_action(params[:item_action])
                 .queued(params[:queued])
                 .with_node(params[:node])
                 .with_pid(params[:pid])
                 .with_unempty_node(params[:node_not_empty])
                 .with_empty_node(params[:node_empty])
                 .with_unempty_pid(params[:pid_not_empty])
                 .with_empty_pid(params[:pid_empty])
                 .with_retry(params[:retry])
    @selected = {}
    get_status_counts(@items)
    get_stage_counts(@items)
    get_action_counts(@items)
    get_institution_counts(@items)
    count = @items.count
    set_page_counts(count)
    params[:sort] = 'date' if params[:sort].nil?
    case params[:sort]
      when 'date'
        @items = @items.order('date DESC')
      when 'name'
        @items = @items.order('name')
      when 'institution'
        @items = @items.joins(:institution).order('institutions.name')
    end
  end

  def check_for_completed_restoration
    if @work_item && @work_item.action == Pharos::Application::PHAROS_ACTIONS['restore'] &&
        @work_item.stage == Pharos::Application::PHAROS_STAGES['record'] &&
        @work_item.status == Pharos::Application::PHAROS_STATUSES['success']
      log = Email.log_restoration(@work_item.id)
      NotificationMailer.restoration_notification(@work_item, log).deliver!
    else
      return
    end
  end
end
