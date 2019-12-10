class VerificationsController < ApplicationController
  skip_before_action :verify_user!

  def login

  end

  def edit

  end

  def update
    if params[:verification_type] == 'login'
      if current_user.validate_and_consume_otp!(params[:code])
        session[:verified] = true
        flash[:notice] = 'Signed in successfully.'
        redirect_to session['user_return_to'] || root_path, flash: { notice: 'Signed in successfully.' }
      else
        redirect_to edit_verification_path(id: params[:id], verification_type: 'login'), flash: { error: 'Incorrect one-time authorization code.' }
      end
    elsif params[:verification_type] == 'phone_number'
      if current_user.validate_and_consume_otp!(params[:code])
        current_user.confirmed_two_factor = true
        current_user.save!
        session[:verified] = true
        redirect_to current_user, flash: { notice: 'Phone number has been verified.' }
      else
        redirect_to current_user, flash: { error: 'Incorrect one-time authorization code, phone number has not been verified.' }
      end
    end
  end

  def enter_backup

  end

  def check_backup
    if current_user.invalidate_otp_backup_code!(params[:code])
      current_user.save!
      session[:verified] = true
      session.delete(:two_factor_option)
      redirect_to session['user_return_to'] || root_path, flash: { notice: 'Signed in successfully.' }
    else
      redirect_to enter_backup_verification_path(id: params[:id]), flash: { error: 'This backup code is either incorrect or has been used previously.' }
    end
  end

end