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

  def generate_one_touch(msg)
    one_touch = Authy::OneTouch.send_approval_request(
        id: current_user.authy_id,
        message: msg,
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

  def check_one_touch_verify(one_touch)
    session[:uuid] = one_touch.approval_request['uuid']
    status = one_touch['success'] ? :onetouch : :sms
    current_user.update(authy_status: status)
    session[:verify_timeout] = 300
    one_touch_status_for_users
  end

  def recheck_one_touch_status
    sleep 1
    session[:one_touch_timeout] -= 1
    one_touch_status
  end

  def recheck_one_touch_status_user
    sleep 1
    session[:verify_timeout] -= 1
    one_touch_status_for_users
  end

  def confirmed_two_factor_updates(usr)
    session.delete(:uuid) || session.delete('uuid')
    usr.confirmed_two_factor = true
    usr.save!
    session[:verified] = true
    bypass_sign_in(usr)
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

  def generate_authy_account(usr)
    authy = Authy::API.register_user(
        email: usr.email,
        cellphone: usr.phone_number,
        country_code: usr.phone_number[1]
    )
    if authy.ok?
      usr.update(authy_id: authy.id)
    else
      authy.errors
    end
    authy
  end

  def current_user_is_an_admin
    current_user.admin? || current_user.institutional_admin?
  end

  def user_is_an_admin(usr)
    usr.admin? || usr.institutional_admin?
  end

  def user_inst_requires_twofa(usr)
    usr.institution.otp_enabled
  end

  def disable_twofa(usr)
    usr.enabled_two_factor = false
    usr.save!
  end

  def update_password_attributes(usr)
    unless usr.initial_password_updated
      usr.initial_password_updated = true
      usr.email_verified = true
    end
    usr.force_password_update = false if usr.force_password_update
    usr.save!
  end

  def update_enable_otp_attributes(usr)
    usr.otp_secret = User.generate_otp_secret
    usr.enabled_two_factor = true
    codes = usr.generate_otp_backup_codes!
    usr.save!
    codes
  end

  def update_account_attributes(usr)
    usr.account_confirmed = false
    usr.save!
  end

  def update_phone_number(usr)
    usr.phone_number = params[:user][:phone_number]
    usr.save!
  end

  def create_user_confirmation_token(usr)
    ConfirmationToken.where(user_id: usr.id).delete_all # delete any old tokens. Only the new one should be valid
    token = ConfirmationToken.create(user: usr, token: SecureRandom.hex)
    token.save!
    token
  end

end