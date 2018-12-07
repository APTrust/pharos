class VerificationsController < ApplicationController
  skip_before_action :verify_user!

  def edit

  end

  def update
    response = client.verify.check(request_id: params[:id], code: params[:code])

    if response.status == 0
    #if current_user.current_otp == params[:code]
      session[:verified] = true
      redirect_to :root_path
    else
      redirect_to edit_verification_path(id: params[:id]), flash: { error: confirmation['error_text'] }
    end
  end
end