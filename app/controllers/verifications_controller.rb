class VerificationsController < ApplicationController
  skip_before_action :verify_user!

  def edit

  end

  def update
    if current_user.current_otp == params[:code]
      session[:verified] = true
      redirect_to :root_path
    else
      redirect_to edit_verification_path(id: params[:id]), flash: { error: confirmation['error_text'] }
    end
  end
end