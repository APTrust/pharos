class IntellectualObjectsController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  before_action :load_institution, only: [:index, :create]
  before_action :load_object, only: [:show, :edit, :update, :destroy]

  def index
    authorize @institution
    if params[:search_field].present?
      filter_results_by_standard_params
      prep_search_incidentals
    elsif params[:alt_action].present?
      @intellectual_object = IntellectualObject.where(identifier: params[:q]).first
    else
      narrow_results_to_specific_institution
      filter_results_by_other_params
      prep_search_incidentals
    end
    respond_to do |format|
      format.json { render json: {count: @count, next: @next, previous: @previous, results: @intellectual_objects.map{ |item| item.serializable_hash(include: [:etag])}} }
      format.html {
        if params[:alt_action].present?
          case params[:alt_action]
            when 'dpn'
              send_to_dpn
            when 'restore'
              restore_item
          end
        else
          index!
        end
      }
    end
  end

  def create
    authorize @institution, :create_through_institution?
    intellectual_object_params
    separate_params
    IntellectualObject.transaction do
      @intellectual_object = @institution.intellectual_objects.new(@object_params)
      @file_params.each { |gf| @intellectual_object.generic_files.new(gf) } unless @file_params.nil?
      raise ActiveRecord::Rollback
    end
    if @intellectual_object.save
      respond_to do |format|
        format.json { render object_as_json, status: :created }
        format.html {
          render status: :created
          super
        }
      end
    else
      respond_to do |format|
        format.json { render json: @intellectual_object.errors, status: :unprocessable_entity }
        format.html {
          render status: :unprocessable_entity
          super
        }
      end
    end

  end

  def show
    authorize @intellectual_object
    if @intellectual_object.nil? || @intellectual_object.state == 'D'
      respond_to do |format|
        format.json { render :nothing => true, :status => 404 }
        format.html
      end
    else
      respond_to do |format|
        format.json { render json: object_as_json }
        format.html
      end
    end
  end

  def edit
    authorize @intellectual_object
    edit!
  end

  def update
    authorize @intellectual_object
    @intellectual_object.update!(intellectual_object_params)
    respond_to do |format|
      format.json { render object_as_json}
      format.html { redirect_to intellectual_object_path(@intellectual_object) }
    end
  end

  def destroy
    authorize @intellectual_object, :soft_delete?
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has already been deleted.'
    elsif pending == 'false'
      attributes = { event_type: 'delete',
                     date_time: "#{Time.now}",
                     detail: 'Object deleted from S3 storage',
                     outcome: 'Success',
                     outcome_detail: current_user.email,
                     object: 'Goamz S3 Client',
                     agent: 'https://github.com/crowdmob/goamz',
                     outcome_information: "Action requested by user from #{current_user.institution_id}",
                     identifier: SecureRandom.uuid
      }
      resource.soft_delete(attributes)
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been queued for object: #{resource.title}. Depending on the size of the object, it may take a few minutes for all associated files to be marked as deleted."
          redirect_to root_path
        }
      end
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be deleted at this time due to a pending #{pending} request."
    end
  end

  protected

  def redirect_after_update
    intellectual_object_path(resource)
  end

  def send_to_dpn
    authorize @intellectual_object, :dpn?
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if Pharos::Application.config.show_send_to_dpn_button == false
      redirect_to @intellectual_object
      flash[:alert] = 'We are not currently sending objects to DPN.'
    elsif @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has been deleted and cannot be sent to DPN.'
    elsif pending == 'false'
      WorkItem.create_dpn_request(@intellectual_object.identifier, current_user.email)
      redirect_to @intellectual_object
      flash[:notice] = 'Your item has been queued for DPN.'
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be sent to DPN at this time due to a pending #{pending} request."
    end
  end

  def restore_item
    authorize @intellectual_object, :restore?
    pending = WorkItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has been deleted and cannot be queued for restoration.'
    elsif pending == 'false'
      WorkItem.create_restore_request(@intellectual_object.identifier, current_user.email)
      redirect_to @intellectual_object
      flash[:notice] = 'Your item has been queued for restoration.'
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be queued for restoration at this time due to a pending #{pending} request."
    end
  end

  def filter_results_by_standard_params
    params[:institution_identifier].present? ?
        @intellectual_objects = @institution.intellectual_objects :
        @intellectual_objects = IntellectualObject.all
    case params[:search_field]
      when 'title'
        @intellectual_objects = @intellectual_objects.where('title LIKE ?', "%#{params[:q]}%")
      when 'description'
        @intellectual_objects = @intellectual_objects.where('description LIKE ?', "%#{params[:q]}%")
      when 'bag_name'
        @intellectual_objects = @intellectual_objects.where('bag_name=? OR bag_name LIKE ?', params[:q], "%#{params[:q]}%")
      when 'alt_identifier'
        @intellectual_objects = @intellectual_objects.where('alt_identifier=? OR alt_identifier LIKE ?', params[:q], "%#{params[:q]}%")
      when 'identifier'
        @intellectual_objects = @intellectual_objects.where('identifier=? OR identifier LIKE ?', params[:q], "%#{params[:q]}%")
    end
  end

  def narrow_results_to_specific_institution
    if current_user.admin?
      if params[:institution].present? then
        @search_institution = Institution.where(identifier: params[:institution_institution]).first
        @intellectual_objects = @search_institution.intellectual_objects
      elsif params[:institution_identifier].present?
        @search_institution = @institution
        @intellectual_objects = @search_institution.intellectual_objects
      else
        @intellectual_objects = IntellectualObject.all
      end
    else
      @search_institution = Institution.find(current_user.institution_id)
      @intellectual_objects = @search_institution.intellectual_objects
    end
  end

  def filter_results_by_other_params
    @intellectual_objects = @intellectual_objects.where(identifier: params[:name_exact]) if params[:name_exact].present?
    @intellectual_objects = @intellectual_objects.where('identifier LIKE ?', "%#{params[:name_contains]}%") if params[:name_contains].present?
    @intellectual_objects = @intellectual_objects.where(state: params[:state]) if params[:state].present?
    if params[:updated_since].present?
      date = format_date
      @intellectual_objects = @intellectual_objects.where(updated_at: date..Time.now)
    end
  end

  def prep_search_incidentals
    @count = @intellectual_objects.count
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    start = ((page - 1) * per_page)
    @intellectual_objects = @intellectual_objects.offset(start).limit(per_page)
    @next = format_next(page, per_page)
    @previous = format_previous(page, per_page)
  end

  def nested_create
    state = {
        current_object: nil,
        object_events: [],
        object_files: [],
    }
    begin
      object_files = params[:intellectual_object][:generic_files_attributes]
      new_object = IntellectualObject.create(params[:intellectual_object])
      object_files.each do |gf|
        new_object.generic_files.new(gf)
      end
      @intellectual_object = new_object
      @institution = @intellectual_object.institution
      respond_to { |format| format.json { render json: object_as_json, status: :created } }
    rescue Exception => ex
      log_exception(ex)
      if !new_object.nil?
        new_object.generic_files.each do |gf|
          gf.destroy
        end
        new_object.destroy
      end
      respond_to { |format| format.json {
        render json: { error: "#{ex.message} : #{state[:current_object]}" }, status: :unprocessable_entity }
      }
    end
  end

  private

  def search_action_url options = {}
    institution_intellectual_objects_path(params[:identifier] || @intellectual_object.institution.identifier)
  end

  def object_as_json
    if params[:include_relations]
      # Return only active files, but call them generic_files
      data = @intellectual_object.serializable_hash(include: [:premis_events, active_files: { include: [:checksum, :premis_events]}])
      data[:generic_files] = data.delete(:active_files)
      data[:state] = @intellectual_object.state
      data
    else
      @intellectual_object.serializable_hash()
    end
  end

  def intellectual_object_params
    params[:intellectual_object] = params[:intellectual_object].first if params[:intellectual_object].kind_of?(Array)
    params.require(:intellectual_object).permit(:id, :institution_id, :title, :description, :access, :identifier,
                                                :bag_name, :alt_identifier, :state, generic_files_attributes:
                                                [:id, :uri, :content_uri, :identifier, :size, :created, :modified, :file_format,
                                                checksums_attributes: [:digest, :algorithm, :datetime, :id],
                                                premis_events_attributes: [:id, :identifier, :event_type, :date_time, :outcome,
                                                :outcome_detail, :outcome_information, :detail, :object, :agent,
                                                :intellectual_object_id, :generic_file_id, :institution_id, :created_at, :updated_at]],
                                                premis_events_attributes: [:id, :identifier, :event_type, :date_time, :outcome,
                                                :outcome_detail, :outcome_information, :detail, :object, :agent,
                                                :intellectual_object_id, :generic_file_id, :institution_id, :created_at, :updated_at])
  end

  def separate_params
    @object_params = {}
    @object_params[:id] = params[:intellectual_object][:id] if params[:intellectual_object][:id].present?
    @object_params[:institution_id] = params[:intellectual_object][:institution_id] if params[:intellectual_object][:institution_id].present?
    @object_params[:title] = params[:intellectual_object][:title] if params[:intellectual_object][:title].present?
    @object_params[:description] = params[:intellectual_object][:description] if params[:intellectual_object][:description].present?
    @object_params[:access] = params[:intellectual_object][:access] if params[:intellectual_object][:access].present?
    @object_params[:identifier] = params[:intellectual_object][:identifier] if params[:intellectual_object][:identifier].present?
    @object_params[:bag_name] = params[:intellectual_object][:bag_name] if params[:intellectual_object][:bag_name].present?
    @object_params[:alt_identifier] = params[:intellectual_object][:alt_identifier] if params[:intellectual_object][:alt_identifier].present?
    @object_params[:state] = params[:intellectual_object][:state] if params[:intellectual_object][:state].present?
    @object_params[:premis_events_attributes] = params[:intellectual_object][:premis_events_attributes] if params[:intellectual_object][:premis_events_attributes].present?
    @file_params = params[:intellectual_object][:generic_files_attributes] if params[:intellectual_object][:generic_files_attributes].present?
  end

  def load_object
    if params[:intellectual_object_identifier]
      identifier = params[:intellectual_object_identifier].gsub(/%2F/i, '/')
      @intellectual_object = IntellectualObject.where(identifier: identifier).first
      if @intellectual_object.nil?
        msg = "IntellectualObject '#{params[:intellectual_object_identifier]}' not found"
        raise ActionController::RoutingError.new(msg)
      end
    else
      @intellectual_object ||= IntellectualObject.find(params[:id])
    end
    @institution = @intellectual_object.institution unless @intellectual_object.nil?
  end

  def load_institution
    if params[:institution_id]
      @institution ||= Institution.find(params[:institution_id])
    else
      @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(identifier: params[:institution_identifier]).first
    end
  end

  def load_institution_for_create_from_json(object)
    @institution = params[:institution_id].nil? ? object.institution : Institution.find(params[:institution_id])
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def format_next(page, per_page)
    if @count.to_f / per_page <= page
      nil
    else
      path = request.fullpath.split('?').first
      new_page = page + 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous(page, per_page)
    if page == 1
      nil
    else
      path = request.fullpath.split('?').first
      new_page = page - 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
    str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
    str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&institution=#{params[:institution_identifier]}" if params[:institution_identifier].present?
    str = str << "&state=#{params[:state]}" if params[:state].present?
    str = str << "&search_field=#{params[:search_field]}" if params[:search_field].present?
    str = str << "&q=#{params[:q]}" if params[:q].present?
    str
  end
end
