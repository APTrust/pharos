class ApplicationController < ActionController::Base
  include ApiAuth
  before_action do
    resource = controller_path.singularize.gsub('/', '_').to_sym
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)

    api_check = request.fullpath.split('/')[1]
    request.format = 'json' if (!api_check.nil? && api_check.include?('api') && params[:format].nil?)
  end

  before_action do
    session[:two_factor_option] = params[:two_factor_option] if session[:two_factor_option].nil?
  end

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_format
  before_action :verify_user!, unless: :devise_controller?

  #before_action :forced_redirections, unless: :devise_controller?

  def verify_user!
    if requires_verification?
      start_verification
    else
      forced_redirections
    end
  end

  def requires_verification?
    if api_request? && user_signed_in?
      return false
    end
    unless current_user.nil?
      session[:verified].nil? && current_user.need_two_factor_authentication?
    end
  end

  def start_verification
    if session[:two_factor_option] == nil
      session.delete(:authy)
      session.delete(:verified)
      redirect_to verification_login_path, flash: { notice: 'You must select an option for two factor sign in.' }
    elsif session[:two_factor_option] == 'Backup Code'
      redirect_to enter_backup_verification_path(id: current_user.id), flash: { alert: 'Please enter a backup code.' }
    elsif session[:two_factor_option] == 'Push Notification'
      one_touch = Authy::OneTouch.send_approval_request(
          id: current_user.authy_id,
          message: 'Request to Login to APTrust Repository Website',
          details: {
              'Email Address' => current_user.email,
          }
      )
      unless one_touch.ok?
        session.delete(:authy)
        session.delete(:verified)
        session.delete(:two_factor_option)
        sign_out(@user)
        respond_to do |format|
          format.json { render json: { error: 'Create Push Error' }, status: :internal_server_error }
          format.html {
            redirect_to new_user_session_path, flash: { error: 'There was an error creating your push notification. Please try again. If the problem persists, please contact your administrator or an APTrust administrator for help.' }
          }
        end
      end
      #puts "**************************Checking one touch contents: #{one_touch.inspect}"
      if one_touch[:errors].nil? || one_touch[:errors].empty?
        session[:uuid] = one_touch.approval_request['uuid']
        status = one_touch['success'] ? :onetouch : :sms
        current_user.update(authy_status: status)
        session[:one_touch_timeout] = 300
        one_touch_status
      else
        session.delete(:authy)
        session.delete(:verified)
        session.delete(:two_factor_option)
        sign_out(@user)
        respond_to do |format|
          format.json { render json: { error: 'Create Push Error', message: one_touch.inspect }, status: :internal_server_error }
          format.html {
            redirect_to new_user_session_path, flash: { error: "There was an error creating your push notification. Please contact your administrator or an APTrust administrator for help, and let them know that the error message was: #{one_touch[:errors][:message]}" }
          }
        end
      end

    elsif session[:two_factor_option] == 'Text Message'
      sms = Aws::SNS::Client.new
      response = sms.publish({
                                 phone_number: current_user.phone_number,
                                 message: "Your new one time password is: #{current_user.current_otp}"
                             })
      redirect_to edit_verification_path(id: current_user.id, verification_type: 'login')
    end
  end

  def one_touch_status
    @user = current_user
    status = Authy::OneTouch.approval_request_status({uuid: session[:uuid]})

    unless status.ok?
      respond_to do |format|
        format.json { render json: { error: 'One Touch Status Error' }, status: :internal_server_error }
        format.html {
          redirect_to root_path, flash: { error: 'There was a problem verifying your push notification. Please try again. If the problem persists, please contact your administrator or an APTrust administrator for help.' }
        }
      end
    end

    if session[:one_touch_timeout] <= 0
      session.delete(:authy)
      session.delete(:verified)
      session.delete(:two_factor_option)
      sign_out(@user)
      redirect_to new_user_session_path, flash: { error: 'This push notification has expired' }
    else
      if status['approval_request']['status'] == 'approved'
        session.delete(:uuid) || session.delete('uuid')
        session[:authy] = true
        session[:verified] = true
        session.delete(:two_factor_option)
        redirect_to session['user_return_to'] || root_path, flash: { notice: 'Signed in successfully.' }
      elsif status['approval_request']['status'] == 'denied'
        session.delete(:authy)
        session.delete(:verified)
        session.delete(:two_factor_option)
        sign_out(@user)
        redirect_to new_user_session_path, flash: { error: 'This request was denied.' }
      else
        sleep 1
        session[:one_touch_timeout] -= 1
        one_touch_status
      end
    end
  end

  def forced_redirections
    if current_user.nil?
      return
    elsif !current_user.initial_password_updated
      if params[:controller] == 'users' && (params[:action] == 'edit_password' || params[:action] == 'update_password' || (params[:action] == 'show' && params[:id] == current_user.id.to_s))
        return
      else
        respond_to do |format|
          format.json {
            redirect_to current_user
            render json: { status: 'error', message: 'Your initial password is only meant to be temporary, please change your password now.' }, status: :locked }
          format.html {
            redirect_to current_user, flash: { error: 'Your initial password is only meant to be temporary, please change your password now.' }
          }
        end
      end
    elsif !current_user.email_verified
      if params[:controller] == 'users' && (params[:action] == 'verify_email' || params[:action] == 'email_confirmation' || params[:action] == 'show') && params[:id] == current_user.id.to_s
        return
      else
        respond_to do |format|
          format.json {
            redirect_to current_user
            render json: { status: 'error', message: 'You are required to verify your email address before you can continue using this website.' }, status: :locked }
          format.html {
            redirect_to current_user, flash: { error: 'You are required to verify your email address before you can continue using this website.' }
          }
        end
      end
    elsif !current_user.account_confirmed
      if params[:controller] == 'users' && (params[:action] == 'show' || params[:action] == 'indiv_confirmation_email' || params[:action] == 'confirm_account') && params[:id] == current_user.id.to_s
        return
      else
        respond_to do |format|
          format.json {
            redirect_to current_user
            render json: { status: 'error', message: 'You must confirm your account every year, please do that by clicking the link in your confirmation email.' }, status: :locked }
          format.html {
            redirect_to current_user, flash: { error: 'You must confirm your account every year, please do that by clicking the link in your confirmation email.' }
          }
        end
      end
    elsif current_user.force_password_update
      if params[:controller] == 'users' && (params[:action] == 'edit_password' || params[:action] == 'update_password' || (params[:action] == 'show' && params[:id] == current_user.id.to_s))
        return
      else
        respond_to do |format|
          format.json {
            redirect_to current_user
            render json: { status: 'error', message: 'One of your admins has requested you change your password now, please do that immediately.' }, status: :locked }
          format.html {
            redirect_to current_user, flash: { error: 'One of your admins has requested you change your password now, please do that immediately.' }
          }
        end
      end
    elsif params[:controller] == 'users' && params[:action] == 'show' && params[:id] == current_user.id.to_s
      return
    else
      # if current_user.required_to_use_twofa?
      #   if !current_user.enabled_two_factor
      #     if params[:controller] == 'users' && params[:action] == 'enable_otp' && params[:id] == current_user.id.to_s
      #       return
      #     else
      #       respond_to do |format|
      #         format.json {
      #           redirect_to current_user
      #           render json: { status: 'error', message: 'You are required to use two factor authentication, please enable it now.' }, status: :locked }
      #         format.html {
      #           redirect_to current_user, flash: { error: 'You are required to use two factor authentication, please enable it now.' }
      #         }
      #       end
      #     end
      #   elsif !current_user.confirmed_two_factor
      #     if params[:controller] == 'users' && params[:action] == 'verify_twofa' && params[:id] == current_user.id.to_s
      #       return
      #     elsif params[:controller] == 'verifications' && (params[:action] == 'edit' || params[:action] == 'update')
      #       return
      #     else
      #       respond_to do |format|
      #         format.json {
      #           redirect_to current_user
      #           render json: { status: 'error', message: 'You are required to use two factor authentication, please verify your phone number now.' }, status: :locked }
      #         format.html {
      #           redirect_to current_user, flash: { error: 'You are required to use two factor authentication, please verify your phone number now.' }
      #         }
      #       end
      #     end
      #   else
      #     return
      #   end
      # else
      #   return
      # end
      return
    end
  end

  # Adds a few additional behaviors into the application controller
  include ApiAuth
  # Authorization mechanism
  include Pundit

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :exception

  skip_before_action :verify_authenticity_token, :if => :api_request?

  # If a User is denied access for an action, return them back to the last page they could view.
  #rescue_from CanCan::AccessDenied do |exception|
  #respond_to do |format|
  #format.html { redirect_to root_url, alert: exception.message }
  #format.json { render :json => { :status => "error", :message => exception.message }, :status => :forbidden }
  #end
  #end

  # Globally rescue authorization errors in controller
  # return 403 Forbidden if permission is denied
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from ActionController::RoutingError do |exception|
    logger.error 'Routing error occurred'
    respond_to do |format|
      format.html { render 'shared/404', status: 404 }
      format.json { render :json => { status: 'error', message: 'The page you were looking for could not be found! If you were searching for a specific object or file, check to make sure you have the correct identifier and try again. If you believe you have reached this message in error, please contact your administrator or an APTrust administrator.' }, status: 404 }
    end
  end

  def catch_404
    raise ActionController::RoutingError.new(params[:path])
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || root_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  private

  def set_format
    request.format = 'html' unless request.format == 'json' || request.format == 'html' || request.format == 'rss'
  end

  def user_not_authorized(exception)
    #policy_name = exception.policy.class.to_s.underscore

    #flash[:error] = I18n.t "pundit.#{policy_name}.#{exception.query}",
    #default: 'You are not authorized to perform this action.'
    respond_to do |format|
      format.html { redirect_to root_url, alert: 'You are not authorized to access this page.' }
      format.json { render :json => { status: 'error', message: 'You are not authorized to access this page.' }, status: :forbidden }
    end
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? && !verifications_controller?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  # Logs an exception with stacktrace
  def log_exception(ex)
    logger.error ex.message
    logger.error ex.backtrace.join("\n")
  end

  # Logs detailed info about what validation failed.
  # Useful for debugging API calls. Don't call this with
  # models that include sensitive info, such as the User
  # model, which includes a password, because this dumps
  # all of the request params into the log.
  def log_model_error(model)
    message = "URL: #{request.original_url}\n" +
        "Params: #{params.inspect}\n"
    if model.nil?
      message += 'Model object is nil.'
    else
      message += "Validation Errors: #{model.errors.full_messages}"
    end
    logger.error message
  end

  def set_page_counts(count)
    @count = count
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    if @count == 0
      @second_number = 0
      @first_number = 0
    else
      @second_number = params[:page].to_i * params[:per_page].to_i
      @first_number = (@second_number.to_i - params[:per_page].to_i) + 1
    end
    @second_number = @count if @second_number > @count
  end

  def page_results(results)
    @page = params[:page].to_i
    @per_page = params[:per_page].to_i
    @paged_results = results.page(@page).per(@per_page)
    @next = format_next
    @current = format_current
    @previous = format_previous
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def to_boolean(str)
    str == 'true'
  end

  def format_current
    params[:page] = @page
    params[:per_page] = @per_page
    new_url = url_for(params.permit(Pharos::Application::PARAMS_HASH))
    new_url
  end

  def format_next
    if @count.to_f / @per_page <= @page
      nil
    else
      new_page = @page + 1
      params[:page] = new_page
      params[:per_page] = @per_page
      new_url = url_for(params.permit(Pharos::Application::PARAMS_HASH))
      new_url
    end
  end

  def format_previous
    if @page == 1
      nil
    else
      new_page = @page - 1
      params[:page] = new_page
      params[:per_page] = @per_page
      new_url = url_for(params.permit(Pharos::Application::PARAMS_HASH))
      new_url
    end
  end

  def add_params(str)
    str = str << "&q=#{URI.escape(params[:q])}" if params[:q].present?
    str = str << "&search_field=#{URI.escape(params[:search_field])}" if params[:search_field].present?
    str = str << "&object_type=#{URI.escape(params[:object_type])}" if params[:object_type].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&item_action=#{params[:item_action]}" if params[:item_action].present?
    str = str << "&stage=#{params[:stage]}" if params[:stage].present?
    str = str << "&status=#{params[:status]}" if params[:status].present?
    str = str << "&access=#{params[:access]}" if params[:access].present?
    str = str << "&file_format=#{params[:file_format]}" if params[:file_format].present?
    str = str << "&file_association=#{params[:file_association]}" if params[:file_association].present?
    str = str << "&object_association=#{params[:object_association]}" if params[:object_association].present?
    str = str << "&type=#{params[:type]}" if params[:type].present?
    str = str << "&sort=#{params[:sort]}" if params[:sort].present?
    str = str << "&state=#{params[:state]}" if params[:state].present?
    str = str << "&institution_identifier=#{params[:institution_identifier]}" if params[:institution_identifier].present?
    str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
    str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
    str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
    str = str << "&node=#{params[:node]}" if params[:node].present?
    str = str << "&needs_admin_review=#{params[:needs_admin_review]}" if params[:needs_admin_review].present?
    str = str << "&event_type=#{params[:event_type]}" if params[:event_type].present?
    str = str << "&outcome=#{params[:outcome]}" if params[:outcome].present?
    str = str << "&not_checked_since=#{params[:not_checked_since]}" if params[:not_checked_since].present?
    str = str << "&identifier_like=#{params[:identifier_like]}" if params[:identifier_like].present?
    str
  end

end
