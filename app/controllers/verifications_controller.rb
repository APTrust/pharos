class VerificationsController < ApplicationController
  skip_before_action :verify_user!

  def edit

  end

  def update
    if params[:verification_type] == 'login'
      if current_user.validate_and_consume_otp!(params[:code])
        session[:verified] = true
        redirect_to session['user_return_to'] || root_path, flash: { notice: 'Signed in successfully.' }
      else
        redirect_to edit_verification_path(id: params[:id]), flash: { error: 'Incorrect one time password.' }
      end
    elsif params[:verification_type] == 'phone_number'
      if current_user.validate_and_consume_otp!(params[:code])
        @user = User.find(params[:id])
        @user.confirmed_two_factor = true
        @user.save!
        redirect_to @user, flash: { notice: 'Your phone number has been verified.' }
      else
        redirect_to current_user, flash: { error: 'Incorrect one time password. Please try again later.' }
      end
    end
  end

  def pending

  end

  def enter_backup

  end

  def check_backup
    if current_user.invalidate_otp_backup_code!(params[:code])
      session[:verified] = true
      redirect_to session['user_return_to'] || root_path, flash: { notice: 'Signed in successfully.' }
    else
      redirect_to enter_backup_verification_path(id: params[:id]), flash: { error: 'Incorrect backup code.' }
    end
  end
end