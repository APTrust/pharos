class AlertsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize current_user, :alert_index?

  end

  def summary
    authorize current_user, :alert_summary?

  end

end