class PremisEventsController < ApplicationController
  include SearchAndIndex
  before_filter :authenticate_user!
  before_filter :load_and_authorize_parent_object, only: [:create]
  after_action :verify_authorized, only: [:index, :create]

  def index
    identifier = params[:identifier].gsub(/%2F/i, '/')
    @premis_events = PremisEvent.discoverable(current_user)
    if (identifier=~/^(\w+)*(\.edu|\.com|\.org)(\%|\/)[\w\-\.]+$/)
      @intellectual_object = IntellectualObject.where(identifier: params[:identifier]).first
      @obj = @intellectual_object
      for_selected_object
    elsif (identifier=~/(\w+)*(\.edu|\.com|\.org)(\%2[Ff]|\/)+[\w\-\/\.]+(\%2[fF]|\/)+[\w\-\/\.\%]+/)
      @generic_file = GenericFile.where(identifier: params[:identifier]).first
      @obj = @generic_file
      for_selected_file
    elsif (identifier=~/(\w+\.)*\w+(\.edu|\.com|\.org)/)
      @institution = Institution.where(identifier: params[:identifier]).first
      @obj = @institution
      for_selected_institution
    end
    authorize @obj
    @events = PremisEvent
      .discoverable(current_user)
      .with_create_date(params[:created_at])
      .created_before(params[:created_before])
      .created_after(params[:created_after])
      .with_type(params[:type])
      .with_event_identifier(params[:event_identifier])
      .with_object_identifier(params[:object_identifier])
      .with_object_identifier_like(params[:object_identifier_like])
      .with_file_identifier(params[:file_identifier])
      .with_file_identifier_like(params[:file_identifier_like])
    filter
    sort
    page_results(@premis_events)
    respond_to do |format|
      format.json { render json: @events.map { |event| event.serializable_hash } }
      format.html { }
    end
  end

  def create
    @event = @parent_object.add_event(params[:premis_event])
    respond_to do |format|
      format.json {
        if @parent_object.save
          render json: @event.serializable_hash, status: :created
        else
          render json: @event.errors, status: :unprocessable_entity
        end
      }
      format.html {
        if @parent_object.save
          flash[:notice] = "Successfully created new event: #{@event.identifier}"
        else
          flash[:alert] = "Unable to create event for #{@parent_object.id} using input parameters: #{params['event']}"
        end
        redirect_to @parent_object
      }
    end
  end

  protected

  def load_intellectual_object
    identifier = params[:identifier].gsub(/%2F/i, '/')
    @parent_object = IntellectualObject.where(identifier: identifier).first
    params[:intellectual_object_id] = @parent_object.id
  end

  def load_generic_file
    identifier = params[:identifier].gsub(/%2F/i, '/')
    @parent_object = GenericFile.where(identifier: identifier).first
    params[:generic_file_id] = @parent_object.id
  end

  def load_and_authorize_parent_object
    if @parent_object.nil?
      identifier = params[:identifier].gsub(/%2F/i, '/')
      (identifier=~/^(\w+)*(\.edu|\.com|\.org)(\%|\/)[\w\-\.]+$/) ? load_intellectual_object : load_generic_file
    end
    authorize @parent_object, :add_event?
  end

  def for_selected_institution
    @premis_events = @premis_events.where(institution_id: @institution.id) unless @institution.nil?
  end

  def for_selected_object
    @premis_events = @premis_events.where(intellectual_object_id: @intellectual_object.id) unless @intellectual_object.nil?
  end

  def for_selected_file
    @premis_events = @premis_events.where(generic_file_id: @generic_file.id) unless @generic_file.nil?
  end

  def sort_chronologically
    @premis_events = @premis_events.order('datetime')
  end

  def premis_event_params
    params.require(:premis_event).permit(:identifier, :event_type, :date_time, :outcome, :outcome_detail,
        :outcome_information, :detail, :object, :agent, :intellectual_object_id, :generic_file_id,
        :institution_id, :created_at, :updated_at)
  end

  def filter
    set_filter_values
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

end

