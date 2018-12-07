class VerificationsController < ApplicationController
  skip_before_action :verify_user!

  def edit

  end

  def update
    if current_user.validate_and_consume_otp!(params[:code])
      session[:verified] = true
      redirect_to session['user_return_to'] || root_path
    else
      redirect_to edit_verification_path(id: params[:id]), flash: { error: 'Incorrect one time password.' }
    end
  end
end