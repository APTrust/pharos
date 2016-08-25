class ApplicationController < ActionController::Base
  before_filter do
    resource = controller_path.singularize.gsub('/', '_').to_sym 
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)
  end

  # Adds a few additional behaviors into the application controller
  include ApiAuth
  # Authorization mechanism
  include Pundit

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

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

  def after_sign_in_path_for(resource)
    root_path()
  end

  private

  def user_not_authorized(exception)
    #policy_name = exception.policy.class.to_s.underscore

    #flash[:error] = I18n.t "pundit.#{policy_name}.#{exception.query}",
    #default: 'You are not authorized to perform this action.'
    respond_to do |format|
      format.html { redirect_to root_url, alert: 'You are not authorized to access this page.' }
      format.json { render :json => { :status => 'error', :message => 'You are not authorized to access this page.' }, :status => :forbidden }
    end
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

end
