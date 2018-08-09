class ApplicationController < ActionController::Base
  before_action do
    resource = controller_path.singularize.gsub('/', '_').to_sym 
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)

    api_check = request.fullpath.split('/')[1]
    request.format = 'json' if (!api_check.nil? && api_check.include?('api') && params[:format].nil?)
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
    session['user_return_to'] || root_path
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
