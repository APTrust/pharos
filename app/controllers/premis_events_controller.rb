class PremisEventsController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
  before_filter :load_and_authorize_parent_object, only: [:create]
  after_action :verify_authorized, only: [:index, :create]

  def index
    @premis_events = PremisEvent.discoverable(current_user)
    if params[:object_identifier]
      load_intellectual_object
    elsif params[:file_identifier]
      load_generic_file
    elsif params[:institution_identifier]
      load_institution
      for_selected_institution
    end
    params[:file_identifier] = '' if params[:file_identifier] == 'null' || params[:file_identifier] == 'blank'
    params[:file_identifier_like] = '' if params[:file_identifier_like] == 'null' || params[:file_identifier_like] == 'blank'

    authorize @parent
    @premis_events = @premis_events
      .with_create_date(params[:created_at])
      .created_before(params[:created_before])
      .created_after(params[:created_after])
      .with_type(params[:event_type])
      .with_event_identifier(params[:event_identifier])
      .with_object_identifier(params[:object_identifier])
      .with_object_identifier_like(params[:object_identifier_like])
      .with_file_identifier(params[:file_identifier])
      .with_file_identifier_like(params[:file_identifier_like])
    filter
    sort
    page_results(@premis_events)
    respond_to do |format|
      format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map { |event| event.serializable_hash } } }
      format.html { }
    end
  end

  # This is a JSON call restricted to the Admin user.
  # The JSON is in the request body, and is parsed in
  # load_and_authorize_parent_object
  def create
    authorize @parent, :add_event?
    @event = @parent.add_event(@json_params)
    respond_to do |format|
      format.json {
        if @parent.save
          render json: @event.serializable_hash, status: :created
        else
          render json: @event.errors, status: :unprocessable_entity
        end
      }
    end
  end

  protected

  def load_intellectual_object
    # Param names should be consistent!
    identifier_param = params[:object_identifier]
    if identifier_param.blank? && !params[:intellectual_object_identifier].blank?
      identifier_param = params[:intellectual_object_identifier]
    end
    identifier = identifier_param.gsub(/%2F/i, '/')
    @parent = IntellectualObject.where(identifier: identifier).first
    params[:intellectual_object_id] = @parent.id
  end

  def load_generic_file
    identifier = params[:file_identifier].gsub(/%2F/i, '/')
    @parent = GenericFile.where(identifier: identifier).first
    params[:generic_file_id] = @parent.id
  end

  def load_institution
    identifier = params[:institution_identifier].gsub(/%2F/i, '/')
    @parent = Institution.where(identifier: identifier).first
    params[:institution_id] = @parent.id
  end

  def load_and_authorize_parent_object
    @json_params = JSON.parse(request.body.read)
    if @parent.nil?
      if !@json_params['generic_file_identifier'].blank?
        @parent = GenericFile.where(identifier: @json_params['generic_file_identifier']).first
      elsif !@json_params['intellectual_object_identifier'].blank?
        @parent = IntellectualObject.where(identifier: @json_params['intellectual_object_identifier']).first
      end
    end
    authorize @parent, :add_event?
  end

  def for_selected_institution
    @premis_events = @premis_events.where(institution_id: @parent.id) unless @parent.nil?
  end

  def for_selected_object
    @premis_events = @premis_events.where(intellectual_object_id: @parent.id) unless @parent.nil?
  end

  def for_selected_file
    @premis_events = @premis_events.where(generic_file_id: @parent.id) unless @parent.nil?
  end

  def filter
    set_filter_values
    #initialize_filter_counters
    filter_by_institution unless params[:institution].nil?
    filter_by_event_type unless params[:event_type].nil?
    filter_by_outcome unless params[:outcome].nil?
    #set_inst_count(@premis_events, :events)
    #set_event_type_count(@premis_events)
    #set_outcome_count(@premis_events)
    count = @premis_events.count
    set_page_counts(count)
  end

  def set_filter_values
    params[:institution] ? @institutions = [params[:institution]] : @institutions = Institution.all.pluck(:id)
    params[:event_type] ? @event_types = [params[:event_type]] : @event_types = []
    params[:outcome] ? @outcomes = [params[:outcome]] : @outcomes = %w(Success Failure)
  end

end
