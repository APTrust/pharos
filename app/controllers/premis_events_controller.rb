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
    authorize @parent
    @premis_events = @premis_events
      .with_create_date(params[:created_at])
      .created_before(params[:created_before])
      .created_after(params[:created_after])
      .with_type(params[:type])
      .with_event_identifier(params[:event_identifier])
      .with_event_identifier_like(params[:event_identifier_like])
      .with_object_identifier(params[:object_identifier])
      .with_object_identifier_like(params[:object_identifier_like])
      .with_file_identifier(params[:file_identifier])
      .with_file_identifier_like(params[:file_identifier_like])
    filter
    sort
    page_results(@premis_events)
    respond_to do |format|
      format.json { render json: @premis_events.map { |event| event.serializable_hash } }
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
    identifier = params[:object_identifier].gsub(/%2F/i, '/')
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
    initialize_filter_counters
    filter_by_institution unless params[:institution].nil?
    filter_by_event_type unless params[:event_type].nil?
    filter_by_outcome unless params[:outcome].nil?
    filter_by_file_association unless params[:file_association].nil?
    filter_by_object_association unless params[:object_association].nil?
    set_inst_count(@premis_events)
    set_event_type_count(@premis_events)
    set_outcome_count(@premis_events)
    set_gf_assc_count(@premis_events)
    set_io_assc_count(@premis_events)
    count = @premis_events.count
    set_page_counts(count)
  end

  def set_filter_values
    @institutions = @premis_events.distinct.pluck(:institution_id)
    @object_associations = @premis_events.distinct.pluck(:intellectual_object_id)
    @file_associations = @premis_events.distinct.pluck(:generic_file_id)
    @event_types = @premis_events.distinct.pluck(:event_type)
    @outcomes = @premis_events.distinct.pluck(:outcome)
  end

end
