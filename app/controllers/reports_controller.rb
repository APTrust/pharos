class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_institution, only: [:index, :overview, :download, :general, :subscribers, :cost, :timeline, :mimetype]
  before_action :set_intellectual_object, only: :object_report
  after_action :verify_authorized

  def index
    authorize @institution
    (@institution.name == 'APTrust') ?
        @overview_report = Institution.generate_overview_apt :
        @overview_report = @institution.generate_overview
    @indiv_timeline_breakdown = @institution.generate_timeline_report
    @inst_breakdown_report = Institution.breakdown if policy(current_user).institution_breakdown?
    respond_to do |format|
      format.json { render json: { overview_report: @overview_report, timeline_report: @indiv_timeline_breakdown, institution_breakdown: @inst_breakdown_report } }
      format.html { }
    end
  end

  def overview
    authorize @institution
    (@institution.name == 'APTrust') ?
        @overview_report = Institution.generate_overview_apt :
        @overview_report = @institution.generate_overview
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

  def general
    authorize @institution, :overview?
    @basic_report = @institution.generate_basic_report
    @nav_type = 'general'
    respond_to do |format|
      format.json { render json: { report: @basic_report } }
      format.html { }
      # format.pdf do
      #   html = render_to_string(action: :general, layout: false)
      #   pdf = WickedPdf.new.pdf_from_string(html)
      #   send_data(pdf, filename: "Basic Overview for #{@institution.name}.pdf", disposition: 'attachment')
      # end
    end
  end

  def subscribers
    authorize @institution, :overview?
    @subscriber_report = @institution.generate_subscriber_report
    @nav_type = 'subscriber'
    respond_to do |format|
      format.json { render json: { report: @subscriber_report } }
      format.html { }
      # format.pdf do
      #   html = render_to_string(action: :subscribers, layout: false)
      #   pdf = WickedPdf.new.pdf_from_string(html)
      #   send_data(pdf, filename: "Subscriber Breakdown for #{@institution.name}.pdf", disposition: 'attachment')
      # end
    end
  end

  def cost
    authorize @institution, :overview?
    @cost_report = @institution.generate_cost_report
    @nav_type = 'cost'
    respond_to do |format|
      format.json { render json: { report: @cost_report } }
      format.html { }
      # format.pdf do
      #   html = render_to_string(action: :cost, layout: false)
      #   pdf = WickedPdf.new.pdf_from_string(html)
      #   send_data(pdf, filename: "Cost Breakdown for #{@institution.name}.pdf", disposition: 'attachment')
      # end
    end
  end

  def timeline
    authorize @institution, :overview?
    @timeline_report = @institution.generate_timeline_report
    @nav_type = 'timeline'
    respond_to do |format|
      format.json { render json: { report: @timeline_report } }
      format.html { }
      # format.pdf do
      #   html = render_to_string(action: :timeline, layout: false)
      #   pdf = WickedPdf.new.pdf_from_string(html)
      #   send_data(pdf, filename: "Timeline for #{@institution.name}.pdf", disposition: 'attachment')
      # end
    end
  end

  def mimetype
    authorize @institution, :overview?
    (@institution.name == 'APTrust') ?
        @mimetype_report = GenericFile.bytes_by_format :
        @mimetype_report = @institution.bytes_by_format
    @nav_type = 'mimetype'
    respond_to do |format|
      format.json { render json: { report: @mimetype_report } }
      format.html { }
      # format.pdf do
      #   html = render_to_string(action: :mimetype, layout: false)
      #   pdf = WickedPdf.new.pdf_from_string(html)
      #   send_data(pdf, filename: "Mimetype Breakdown for #{@institution.name}.pdf", disposition: 'attachment')
      # end
    end
  end

  def institution_breakdown
    authorize current_user
    @institution = current_user.institution
    @inst_breakdown_report = Institution.breakdown
    @report_time = Time.now
    @nav_type = 'breakdown'
    respond_to do |format|
      format.json { render json: { report: @inst_breakdown_report } }
      format.html { }
      format.pdf do
        html = render_to_string(action: :institution_breakdown, layout: false)
        pdf = WickedPdf.new.pdf_from_string(html)
        send_data(pdf, filename: 'Institution Breakdown.pdf', disposition: 'attachment')

        # Use this block to test layouts (PDF viewed in browser), block above provides downloadable PDF
        # render pdf: "Institution Breakdown.pdf",
        #        disposition: 'inline',
        #        template: 'reports/institution_breakdown.pdf.erb',
        #        layout: false
      end
    end
  end

  def object_report
    authorize @intellectual_object
    @institution = @intellectual_object.institution unless @intellectual_object.nil?
    if @intellectual_object.nil?
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

end
