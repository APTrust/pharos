class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_institution, only: [:index, :overview, :download]
  before_action :set_intellectual_object, only: :object_report
  after_action :verify_authorized

  def index
    authorize @institution
    overview_wrapper
    @indiv_timeline_breakdown = @institution.monthly_breakdown
    @inst_breakdown_report = Institution.breakdown if policy(current_user).institution_breakdown?
    respond_to do |format|
      format.json { render json: { report_list: 'There is one report available, a general overview found at reports/overview/:identifier' } }
      format.html { }
    end
  end

  def overview
    authorize @institution
    overview_wrapper
    respond_to do |format|
      format.json { render json: { report: @overview_report } }
      format.html { }
      format.pdf do
        html = render_to_string(action: :overview, layout: false)
        pdf = WickedPdf.new.pdf_from_string(html)
        send_data(pdf, filename: "Overview for #{@institution.name}.pdf", disposition: 'attachment')

        # Use this block to test layouts (PDF viewed in browser), block above provides downloadable PDF
        # render pdf: "Overview for #{@institution.name}.pdf",
        #        disposition: 'inline',
        #        template: 'reports/overview.pdf.erb',
        #        layout: false
      end
    end
  end

  def institution_breakdown
    authorize current_user
    @inst_breakdown_report = Institution.breakdown
    respond_to do |format|
      format.json { render json: { report: @inst_breakdown_report } }
      format.html { }
      format.pdf do
        html = render_to_string(action: :institution_breakdown, layout: false)
        pdf = WickedPdf.new.pdf_from_string(html)
        send_data(pdf, filename: 'Institution Breakdown.pdf', disposition: 'attachment')
      end
    end
  end

  def object_report
    authorize @intellectual_object
    @institution = @intellectual_object.institution unless @intellectual_object.nil?
    if @intellectual_object.nil? || @intellectual_object.state == 'D'
      respond_to do |format|
        format.json { render :nothing => true, :status => 404 }
        format.html
      end
    else
      @object_report = @intellectual_object.object_report
      respond_to do |format|
        format.json { render json: @object_report }
        format.html
      end
    end
  end

  private

  def set_institution
    @institution = Institution.where(identifier: params[:identifier]).first
  end

  def set_intellectual_object
    if params[:intellectual_object_identifier]
      @intellectual_object = IntellectualObject.where(identifier: params[:intellectual_object_identifier]).first
      if @intellectual_object.nil?
        msg = "IntellectualObject '#{params[:intellectual_object_identifier]}' not found"
        raise ActionController::RoutingError.new(msg)
      end
    else
      @intellectual_object ||= IntellectualObject.readable(current_user).find(params[:id])
    end
  end

  def overview_wrapper
    (@institution.name == 'APTrust') ?
        @overview_report = @institution.generate_overview_apt :
        @overview_report = @institution.generate_overview
  end

end
