class EmailsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    @emails = Email.all
    authorize @emails
  end

  def show
    @email = Email.find(params[:id])
    authorize @email
  end
end
