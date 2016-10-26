class ReportsController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized
  before_filter :set_institution, only: [:index, :overview]

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
        # pdf = WickedPdf.new.pdf_from_html_file('/views/reports/_overview.html.erb')
        pdf = render_to_string pdf: 'Overview_Report', template: 'views/reports/_overview.html.erb', encoding: 'UTF-8'
        save_path = Rails.root.join('pdfs','Overview_Report.pdf')
        File.open(save_path, 'wb') do |file|
          file << pdf
        end
      end
    end
  end

  private

  def set_institution
    @institution = Institution.where(identifier: params[:identifier]).first
  end

end
