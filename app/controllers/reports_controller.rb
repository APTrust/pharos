class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_institution, only: [:index, :overview, :download]
  after_action :verify_authorized

  def index
    authorize @institution
    respond_to do |format|
      format.json { render json: { report_list: 'There is one report available, a general overview found at reports/overview/:identifier' } }
      format.html { }
    end
  end

  def overview
    authorize @institution
    (@institution.name == 'APTrust') ?
        @report = @institution.generate_overview_apt :
        @report = @institution.generate_overview
    respond_to do |format|
      format.json { render json: { report: @report } }
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
    @report = Institution.breakdown
    respond_to do |format|
      format.json { render json: { report: @report } }
      format.html { }
      format.pdf do
        html = render_to_string(action: :institution_breakdown, layout: false)
        pdf = WickedPdf.new.pdf_from_string(html)
        send_data(pdf, filename: 'Institution Breakdown.pdf', disposition: 'attachment')
      end
    end
  end

  private

  def set_institution
    @institution = Institution.where(identifier: params[:identifier]).first
  end

end
