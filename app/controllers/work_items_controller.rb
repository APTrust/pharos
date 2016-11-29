class WorkItemsController < ApplicationController
  include SearchAndIndex
  respond_to :html, :json
  before_filter :authenticate_user!
  before_filter :set_item, only: :show
  before_filter :init_from_params, only: :create
  after_action :verify_authorized

  def index
    set_items
    filter unless request.format == :json
    sort
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
          json_list = @paged_results.map { |item| item.serializable_hash(except: [:node, :pid]) }
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
      respond_to do |format|
        if current_user.admin?
          item = @work_item.serializable_hash
        else
          item = @work_item.serializable_hash(except: [:node, :pid])
        end
        format.json { render json: item }
        format.html
      end
    else
      authorize current_user, :nil_index?
      respond_to do |format|
        format.json { render nothing: true, status: :not_found }
        format.html { render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found }
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
          wi.user = current_user.email
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
    restore = Pharos::Application::PHAROS_ACTIONS['restore']
    @item = WorkItem.where(object_identifier: params[:object_identifier],
                           action: restore).order(created_at: :desc).first
    if @item.nil?
      authorize current_user
      render nothing: true, status: :not_found and return
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

  def api_search
    authorize WorkItem, :admin_api?
    current_user.admin? ? @items = WorkItem.all : @items = WorkItem.with_institution(current_user.institution_id)
    if Rails.env.test? || Rails.env.development?
      rewrite_params_for_sqlite
    end
    search_fields = [:name, :etag, :bag_date, :stage, :status, :institution,
                     :retry, :object_identifier, :generic_file_identifier,
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

  def array_as_json(list_of_work_items)
    list_of_work_items.map { |item| item.serializable_hash }
  end

  def init_from_params
    @work_item = WorkItem.new(writable_work_item_params)
    @work_item.user = current_user.email
  end

  def find_and_update
    # Parse date explicitly, or ActiveRecord will not find records when date format string varies.
    set_item
    if @work_item
      @work_item.update(writable_work_item_params)
      @work_item.user = current_user.email
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
                                      :pid, :node, :object_identifier,
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

  def set_items
    if current_user.admin?
      params[:institution].present? ? @items = WorkItem.with_institution(params[:institution]) : @items = WorkItem.all
    else
      @items = WorkItem.readable(current_user)
    end
    params[:institution].present? ? @institution = Institution.find(params[:institution]) : @institution = current_user.institution
    params[:sort] = 'date' if params[:sort].nil?
    @items = @items
      .created_before(params[:created_before])
      .created_after(params[:created_after])
      .updated_before(params[:updated_before])
      .updated_after(params[:updated_after])
      .with_bag_date(params[:bag_date])
      .with_name(params[:name])
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
      .with_access(params[:access])
      .queued(params[:queued])
    count = @items.count
    set_page_counts(count)
  end

  def set_item
    @institution = current_user.institution
    if Rails.env.test? || Rails.env.development?
      rewrite_params_for_sqlite
    end
    if params[:id].blank? == false
      begin
        @work_item = WorkItem.find(params[:id])
      rescue
        # If we don't catch this, we get an internal server error
      end
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
  end

  def rewrite_params_for_sqlite
    # SQLite wants t or f for booleans
    if params[:retry].present? && params[:retry].is_a?(String)
      params[:retry] = params[:retry][0]
    end
  end

  def filter
    set_filter_values
    initialize_filter_counters
    filter_by_status unless params[:status].nil?
    filter_by_stage unless params[:stage].nil?
    filter_by_action unless params[:item_action].nil?
    filter_by_institution unless params[:institution].nil?
    filter_by_access unless params[:access].nil?
    filter_by_object_association unless params[:object_association].nil?
    filter_by_file_association unless params[:file_association].nil?
    filter_by_state unless params[:state].nil?
    date = format_date if params[:updated_since].present?
    pattern = '%' + params[:name_contains] + '%' if params[:name_contains].present?
    @items = @items.with_name(params[:name_exact])
    @items = @items.with_name_like(pattern) if pattern
    @items = @items.updated_after(date) if date
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

  def set_filter_values
    @statuses = @items.distinct.pluck(:status)
    @stages = @items.distinct.pluck(:stage)
    @actions = @items.distinct.pluck(:action)
    @institutions = @items.distinct.pluck(:institution_id)
    @accesses = %w(consortia institution restricted)
    @object_associations = @items.distinct.pluck(:intellectual_object_id)
    @file_associations = @items.distinct.pluck(:generic_file_id)
  end
end
