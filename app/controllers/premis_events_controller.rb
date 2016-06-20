class PremisEventsController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_intellectual_object, if: :intellectual_object_identifier_exists?
  #before_filter :load_generic_file, if: :generic_file_identifier_exists?
  before_filter :load_and_authorize_parent_object, only: [:create]

  after_action :verify_authorized, only: [:index, :create]

  def index
    if (params[:identifier]=~/^(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.]+$/)
      @intellectual_object = IntellectualObject.where(identifier: params[:identifier]).first
      obj = @intellectual_object
    elsif (params[:identifier]=~/(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.\/]+/)
      @generic_file = GenericFile.where(identifier: params[:identifier]).first
      obj = @generic_file
    elsif (params[:identifier]=~/(\w+\.)*\w+(\.edu|\.com|\.org)/)
      @institution = Institution.where(identifier: params[:identifier]).first
      obj = @institution
    end
    authorize obj
    @document_list = obj.premis_events
    respond_to do |format|
      format.json { render json: obj.premis_events.map { |event| event.serializable_hash } }
      format.html { }
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

  # def intellectual_object_identifier_exists?
  #   params[:identifier] && params[:identifier] =~ /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.]+/
  # end
  #
  # def generic_file_identifier_exists?
  #   params[:identifier] && params[:identifier] =~ /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.\/]+/
  # end

  def load_intellectual_object
    @parent_object = IntellectualObject.where(identifier: params[:identifier]).first
    params[:intellectual_object_id] = @parent_object.id
  end

  def load_generic_file
    @parent_object = GenericFile.where(identifier: params[:identifier]).first
    params[:generic_file_id] = @parent_object.id
  end

  def load_and_authorize_parent_object
    if @parent_object.nil?
      (params[:identifier]=~/^(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.]+$/) ? load_intellectual_object : load_generic_file
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
    params.require(:intellectual_object).permit(:identifier, :event_type, :date_time, :outcome, :outcome_detail,
        :outcome_information, :date_time, :detail, :object, :agent, :intellectual_object_id, :generic_file_id,
        :institution_id, :created_at, :updated_at)
  end

end

