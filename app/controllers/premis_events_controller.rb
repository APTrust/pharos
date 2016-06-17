class PremisEventsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_intellectual_object, if: :intellectual_object_identifier_exists?
  before_filter :load_generic_file, if: :generic_file_identifier_exists?
  before_filter :load_and_authorize_parent_object, only: [:create]

  after_action :verify_authorized, only: [:index, :create]

  def index
    if params['identifier']
      @institution = Institution.where(identifier: params['identifier']).first
      obj = @institution
    elsif params['intellectual_object_identifier']
      @intellectual_object = IntellectualObject.where(identifier: params['intellectual_object_identifier']).first
      obj = @intellectual_object
    elsif params['generic_file_identifier']
      @generic_file = GenericFile.where(identifier: params['generic_file_identifier']).first
      obj = @generic_file
    end
    authorize obj
    respond_to do |format|
      format.json { render json: obj.premis_events.events.map { |event| event.serializable_hash } }
      format.html {super}
    end
  end

  def create
    @event = @parent_object.add_event(params['event'])
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

  def intellectual_object_identifier_exists?
    params['identifier']
  end

  def generic_file_identifier_exists?
    params['identifier'].contains?('data')
  end

  def load_intellectual_object
    objId = params[:identifier].gsub(/%2F/i, '/')
    @parent_object = IntellectualObject.where(identifier: objId).first
    params[:intellectual_object_id] = @parent_object.id
  end

  def load_generic_file
    gfid = params[:generic_file_identifier].gsub(/%2F/i, '/')
    @parent_object = GenericFile.where(identifier: gfid).first
    params[:generic_file_id] = @parent_object.id
  end

  def load_and_authorize_parent_object
    if @parent_object.nil?
      params[:identifier].contains?('data') ? load_intellectual_object : load_generic_file
    end
    authorize @parent_object, :add_event?
  end

  def for_selected_institution
    return unless @institution
    @premis_events = @premis_events.where(institution_id: @institution.id)
  end

  def for_selected_object
    return unless @intellectual_object
    @premis_events = @premis_events.where(intellectual_object_id: @intellectual_object.id)
  end

  def for_selected_file
    return unless @generic_file
    @premis_events = @premis_events.where(generic_file_id: generic_file.id)
  end

  def sort_chronologically
    @premis_events = @premis_events.order('datetime')
  end

  def event_params
    params.require(:intellectual_object).permit(
        :identifier,
        :type,
        :outcome,
        :outcome_detail,
        :outcome_information,
        :date_time,
        :detail,
        :object,
        :agent)
  end

end

