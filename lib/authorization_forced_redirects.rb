module AuthorizationForcedRedirects
  def delete_session_variables
    session.delete(:authy)
    session.delete(:verified)
    session.delete(:two_factor_option)
  end

  def approve_session
    session.delete(:uuid) || session.delete('uuid')
    session[:authy] = true
    session[:verified] = true
    session.delete(:two_factor_option)
  end

  def generate_one_touch
    one_touch = Authy::OneTouch.send_approval_request(
        id: current_user.authy_id,
        message: 'Request to Login to APTrust Repository Website',
        details: {
            'Email Address' => current_user.email,
        }
    )
    one_touch
  end

  def check_one_touch(one_touch)
    session[:uuid] = one_touch.approval_request['uuid']
    status = one_touch['success'] ? :onetouch : :sms
    current_user.update(authy_status: status)
    session[:one_touch_timeout] = 300
    one_touch_status
  end

  def recheck_one_touch_status
    sleep 1
    session[:one_touch_timeout] -= 1
    one_touch_status
  end

  def send_sms
    sms = Aws::SNS::Client.new
    response = sms.publish({
                               phone_number: current_user.phone_number,
                               message: "Your new one time password is: #{current_user.current_otp}"
                           })
  end

  def right_controller
    params[:controller] == 'users'
  end

  def right_action(type)
    case type
      when 'password'
        (params[:action] == 'edit_password' || params[:action] == 'update_password' || (params[:action] == 'show' && params[:id] == current_user.id.to_s))
      when 'email'
        params[:action] == 'verify_email' || params[:action] == 'email_confirmation' || params[:action] == 'show'
      when 'account'
        params[:action] == 'show' || params[:action] == 'indiv_confirmation_email' || params[:action] == 'confirm_account'
      when 'release'
        params[:action] == 'show'
      when 'twofa_enable'
        params[:action] == 'enable_otp'
      when 'twofa_confirm'
        params[:action] == 'verify_twofa'
      when 'verification'
        params[:action] == 'edit' || params[:action] == 'update'
    end
  end

  def right_controller_and_id
    params[:controller] == 'users' && params[:id] == current_user.id.to_s
  end

  def forced_redirect_return(msg)
    respond_to do |format|
      format.json {
        render json: { status: 'error', message: msg }, status: :locked }
      format.html {
        redirect_to current_user, flash: { error: msg }
      }
    end
  end

end