class ReportsController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized
  before_filter :set_institution, only: [:index, :overview, :download]

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
        html = render_to_string(action: :overview, layout: 'reports/overview.pdf.erb')
        pdf = WickedPdf.new.pdf_from_string(html)
        send_data(pdf, filename: "Overview for #{@institution.name}", disposition: 'attachment')

        # save_path = Rails.root.join('pdfs','filename.pdf')
        # File.open(save_path, 'wb') do |file|
        #   file << pdf
        # end
      end
    end
  end

  def download
    authorize @institution, :overview?
    respond_to do |format|

    end
  end

  private

  def set_institution
    @institution = Institution.where(identifier: params[:identifier]).first
  end

end
