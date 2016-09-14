class ReportsController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized
  before_filter :set_institution, only: [:index]

  def index
    authorize @institution
    respond_to do |format|
      format.json { render json: { report_list: 'There are no reports available yet. Check back later for a list.' } }
      format.html { }
    end
  end

  private

  def set_institution
    @institution = Institution.where(identifier: params[:identifier]).first
  end

end
