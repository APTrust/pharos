class WorkItemsController < ApplicationController
  include SearchAndIndex
  respond_to :html, :json
  before_filter :authenticate_user!
  before_filter :set_item, only: :show
  before_filter :init_from_params, only: :create
  before_filter :find_and_update, only: :update

  def index
    unless (session[:select_notice].nil? || session[:select_notice] == '')
      flash[:notice] = session[:select_notice]
      session[:select_notice] = ''
    end
    if params[:show_reviewed]
      show_reviewed
    elsif params[:review_all]
      review_all
    elsif params[:review]
      review_selected
    else
      set_items
      filter
      sort
      page_results(@items)
      if params[:format] == 'json'
        json_list = @paged_results.map { |item| item.serializable_hash(except: [:state, :node, :pid]) }
        render json: {count: @count, next: @next, previous: @previous, results: json_list}
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
    authorize @work_item
    respond_to do |format|
      if current_user.admin?
        item = @work_item.serializable_hash
      else
        item = @work_item.serializable_hash(except: [:state, :node, :pid])
      end
      format.json { render json: item }
      format.html
    end
  end

  # Note that this method is available through the admin API, but is
  # not accessible to members. If we ever make it accessible to members,
  # we MUST NOT allow them to update :state, :node, or :pid!
  def update
    authorize @work_item
    respond_to do |format|
      if @work_item.save
        format.json { render json: @work_item, status: :ok }
      else
        format.json { render json: @work_item.errors, status: :unprocessable_entity }
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
    restore = Pharos::Application::PHAROS_ACTIONS['restore']
    @item = WorkItem.where(object_identifier: params[:object_identifier],
                           action: restore).order(created_at: :desc).first
    authorize (@item || WorkItem.new), :set_restoration_status?
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

  def api_search
    authorize WorkItem, :admin_api?
    current_user.admin? ? @items = WorkItem.all : @items = WorkItem.with_institution(current_user.institution_id)
    if Rails.env.test? || Rails.env.development?
      rewrite_params_for_sqlite
    end
    search_fields = [:name, :etag, :bag_date, :stage, :status, :institution,
                     :retry, :reviewed, :object_identifier, :generic_file_identifier,
                     :node, :needs_admin_review, :process_after]
    search_fields.each do |field|
      if params[field].present?
        if field == :bag_date && (Rails.env.test? || Rails.env.development?)
          @items = @items.where('datetime(bag_date) = datetime(?)', params[:bag_date])
        elsif field == :node and params[field] == 'null'
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

  def show_reviewed
    authorize @items
    session[:show_reviewed] = params[:show_reviewed]
    respond_to do |format|
      format.js {}
    end
  end

  def review_all
    current_user.admin? ? items = WorkItem.all : items = WorkItem.where(institution_id: current_user.institution_id)
    authorize items, :review_all?
    items.each do |item|
      if item.date < session[:purge_datetime] && (item.status == Pharos::Application::PHAROS_STATUSES['success'] || item.status == Pharos::Application::PHAROS_STATUSES['fail'])
        item.reviewed = true
        item.save!
      end
    end
    session[:purge_datetime] = Time.now.utc
    redirect_to :back
    flash[:notice] = 'All items have been marked as reviewed.'
  rescue ActionController::RedirectBackError
    redirect_to root_path
    flash[:notice] = 'All items have been marked as reviewed.'
  end

  def review_selected
    review_list = params[:review]
    unless review_list.nil?
      review_list.each do |item|
        id = item.split("_")[1]
        proc_item = WorkItem.find(id)
        authorize proc_item, :mark_as_reviewed?
        if (proc_item.status == Pharos::Application::PHAROS_STATUSES['success'] || proc_item.status == Pharos::Application::PHAROS_STATUSES['fail'])
          proc_item.reviewed = true
          proc_item.save!
        end
      end
    end
    set_items
    session[:select_notice] = 'Selected items have been marked for review or purge from S3 as indicated.'
    count = @items.count || 1  # one if single item
    respond_to do |format|
      format.json { render json: {status: 'ok', message: "Marked #{count} items as reviewed"} }
      format.html { redirect_to :back }
    end
  end

  def init_from_params
    @work_item = WorkItem.new(work_item_params)
    @work_item.user = current_user.email
  end

  def find_and_update
    # Parse date explicitly, or ActiveRecord will not find records when date format string varies.
    set_item
    if @work_item
      @work_item.update(work_item_params)
      @work_item.user = current_user.email
    end
  end

  def work_item_params
    params.require(:work_item).permit(:name, :etag, :bag_date, :bucket,
                                      :institution_id, :date, :note, :action,
                                      :stage, :status, :outcome, :retry, :reviewed,
                                      :state, :node)
  end

  def params_for_status_update
    params.permit(:object_identifier, :stage, :status, :note, :retry,
                  :state, :node, :pid, :needs_admin_review)
  end

  def set_items
    if current_user.admin?
      params[:institution].present? ? @items = WorkItem.with_institution(params[:institution]) : @items = WorkItem.all
    else
      @items = WorkItem.readable(current_user)
    end
    params[:institution].present? ? @institution = Institution.find(params[:institution]) : @institution = current_user.institution
    @items = @items.reviewed(false) unless session[:show_reviewed] == 'true'
    params[:sort] = 'date' if params[:sort].nil?
    @items = @items.order(params[:sort])
    @items = @items.reverse_order if params[:sort] == 'date'
    authorize @items
    session[:purge_datetime] = Time.now.utc if params[:page] == 1 || params[:page].nil?
  end

  def set_item
    @institution = current_user.institution
    if Rails.env.test? || Rails.env.development?
      rewrite_params_for_sqlite
    end
    if params[:id].blank? == false
      @work_item = WorkItem.find(params[:id])
    else
      if Rails.env.test? || Rails.env.development?
        # Cursing ActiveRecord + SQLite. SQLite has all the milliseconds wrong!
        @work_item = WorkItem.where(etag: params[:etag],
                                    name: params[:name])
        @work_item = @work_item.where('datetime(bag_date) = datetime(?)', params[:bag_date]).first
      else
        @work_item = WorkItem.where(etag: params[:etag],
                                    name: params[:name],
                                    bag_date: params[:bag_date]).first
      end
    end
    if @work_item
      params[:id] = @work_item.id
    else
      # API callers **DEPEND** on getting a 404 if the record does
      # not exist. This is how they know that an item has not started
      # the ingestion process. So if @work_item is nil, return
      # 404 now. Otherwise, the call to authorize below will result
      # in a 500 error from pundit.
      raise ActiveRecord::RecordNotFound
    end
    authorize @work_item, :show?
  end

  def rewrite_params_for_sqlite
    # SQLite wants t or f for booleans
    if params[:retry].present? && params[:retry].is_a?(String)
      params[:retry] = params[:retry][0]
    end
    if params[:reviewed].present? && params[:retry].is_a?(String)
      params[:reviewed] = params[:reviewed][0]
    end
  end

  def filter
    set_filter_values
    filter_by_status unless params[:status].nil?
    filter_by_stage unless params[:stage].nil?
    filter_by_action unless params[:item_action].nil?
    filter_by_institution unless params[:institution].nil?
    filter_by_access unless params[:access].nil?
    filter_by_association unless params[:association].nil?
    filter_by_state unless params[:state].nil?
    date = format_date if params[:updated_since].present?
    pattern = '%' + params[:name_contains] + '%' if params[:name_contains].present?
    @items = @items.with_name(params[:name_exact])
    @items = @items.with_name_like(pattern) if pattern
    @items = @items.updated_after(date) if date
    @items = @items.reviewed(to_boolean(params[:reviewed]))
    set_status_count(@items)
    set_stage_count(@items)
    set_action_count(@items)
    set_inst_count(@items)
    set_access_count(@items)
    set_io_assc_count(@items)
    set_gf_assc_count(@items)
    count = @items.count
    set_page_counts(count)
  end

end
