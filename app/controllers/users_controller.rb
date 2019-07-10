class UsersController < ApplicationController
  require 'authy'
  inherit_resources
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :generate_api_key, :admin_password_reset, :deactivate, :reactivate,
                                  :vacuum, :enable_otp, :disable_otp, :register_authy_user, :verify_twofa, :generate_backup_codes,
                                  :verify_email, :email_confirmation, :forced_password_update, :indiv_confirmation_email, :confirm_account,
                                  :change_authy_phone_number]
  after_action :verify_authorized, :except => :index
  after_action :verify_policy_scoped, :only => :index

  def index
    @users = policy_scope(User)
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    @user = build_resource
    authorize @user
    create!(notice: 'User was successfully created.')
    if @user.save
      session[:user_id] = @user.id

      # authy = Authy::API.register_user(
      #     email: @user.email,
      #     cellphone: @user.phone_number,
      #     country_code: @user.phone_number[1]
      # )
      # @user.update(authy_id: authy.id)

      password = "ABCabc-#{SecureRandom.hex(4)}"
      @user.password = password
      @user.password_confirmation = password
      @user.save!
      NotificationMailer.welcome_email(@user, password).deliver!
    end
  end

  def show
    authorize @user
    show!
  end

  def edit
    authorize @user
    edit!
  end

  def update
    authorize @user
    update!
  end

  def destroy
    authorize @user
    destroy!(notice: "User #{@user.to_s} was deleted.")
  end

  def edit_password
    @user = current_user
    authorize @user
  end

  def update_password
    @user = User.find(current_user.id)
    authorize @user
    if @user.update_with_password(user_params)
      update_password_attributes(@user)
      bypass_sign_in(@user)
      redirect_to @user
      flash[:notice] = 'Successfully changed password.'
    else
      render :edit_password
    end
  end

  def forced_password_update
    authorize @user
    @user.force_password_update = true
    @user.save!
    respond_to do |format|
      format.json { render json: { message: 'This user will be forced to change their password upon next login.' }, status: :ok }
      format.html { redirect_to @user, flash: { notice: 'This user will be forced to change their password upon next login.' } }
    end
  end

  def enable_otp
    authorize @user
    unless Rails.env.test?
      authy = generate_authy_account(@user) if (@user.authy_id.nil? || @user.authy_id == '')
    end
    if authy && !authy['errors'].nil? && !authy['errors'].empty?
      logger.info "Testing Authy Errors hash: #{authy.errors.inspect}"
      msg = 'An error occurred while trying to enable Two Factor Authentication.'
      flash[:error] = msg
    else
      @codes = update_enable_otp_attributes(@user)
      (current_user == @user) ? usr = ' for your account' : usr = ' for this user'
      msg = "Two Factor Authentication has been enabled#{usr}. Authy ID is #{@user.authy_id}."
      flash[:notice] = msg
    end
    respond_to do |format|
      format.json { render json: { user: @user, codes: @codes, message: msg } }
      format.html { (params[:redirect_loc] && params[:redirect_loc] == 'index') ? redirect_to users_path : render 'show' }
    end
  end

  def disable_otp
    authorize @user
    if current_user_is_an_admin
      if current_user == @user || user_is_an_admin(@user)
        (current_user == @user) ? msg_opt = 'you based on your role as an administrator' : msg_opt = 'this user based on their role as an administrator'
        msg = "Two Factor Authentication cannot be disabled at this time because it is required for #{msg_opt}."
        flash[:alert] = msg
      elsif user_inst_requires_twofa(@user)
        msg = 'Two Factor Authentication cannot be disabled at this time because it is required for all users at this institution.'
        flash[:alert] = msg
      else
        disable_twofa(@user)
        msg = 'Two Factor Authentication has been disabled for this user.'
        flash[:notice] = msg
      end
    else
      if user_inst_requires_twofa(@user)
        msg = 'Two Factor Authentication cannot be disabled at this time because it is required for all users at your institution.'
        flash[:alert] = msg
      else
        disable_twofa(@user)
        msg = 'Two Factor Authentication has been disabled.'
        flash[:notice] = msg
      end
    end
    respond_to do |format|
      format.json { render json: { user: @user, message: msg } }
      format.html { (params[:redirect_loc] && params[:redirect_loc] == 'index') ? redirect_to users_path : redirect_to @user }
    end
  end

  def register_authy_user
    authorize @user
    if @user.authy_id.nil? || @user.authy_id == ''
      authy = Authy::API.register_user(
          email: @user.email,
          cellphone: @user.phone_number,
          country_code: @user.phone_number[1]
      )
      if authy.ok?
        @user.update(authy_id: authy.id)
      else
        authy.errors
      end
    end
    if authy && !authy['errors'].nil? && !authy['errors'].empty?
      logger.info "Testing Authy Errors hash: #{authy.errors.inspect}"
      puts "************************Testing Authy Errors hash: #{authy.errors.inspect}"
      flash[:error] = 'An error occurred while trying to register for Authy.'
      message = 'An error occurred while trying to register for Authy.'
    else
      flash[:notice] = "Registered for Authy. Authy ID is #{@user.authy_id}."
      message = "Registered for Authy. Authy ID is #{@user.authy_id}."
    end
    respond_to do |format|
      format.json { render json: { user: @user, message: message } }
      format.html { render 'show' }
    end
  end

  def change_authy_phone_number
    authorize @user
    @user.phone_number = params[:user][:phone_number]
    @user.save!
    response = Authy::API.delete_user(id: @user.authy_id)
    if response.ok?
      @user.update(authy_id: nil)
      second_response = Authy::API.register_user(
          email: @user.email,
          cellphone: @user.phone_number,
          country_code: @user.phone_number[1]
      )
      if second_response.ok?
        @user.update(authy_id: second_response.id)
        respond_to do |format|
          message = 'The phone number for both this Pharos account and Authy account has been successfully updated.'
          format.json { render json: { user: @user, message: message } }
          format.html { redirect_to @user, flash: { notice: message } }
        end
      else
        respond_to do |format|
          message = 'The Authy account was unable to be updated at this time, you will not be able to use Authy push notifications'
                      + 'until it has been properly updated. If you now see a "Register with Authy" button, please try using that.'
          format.json { render json: { user: @user, message: message } }
          format.html { redirect_to @user, flash: { error: message } }
        end
      end
    else
      respond_to do |format|
        message = 'The Authy account was unable to be updated at this time, you will not be able to use Authy push notifications until it has been properly updated. Please try again later.'
        format.json { render json: { user: @user, message: message } }
        format.html { redirect_to @user, flash: { error: message } }
      end
    end
  end

  def generate_backup_codes
    authorize @user
    @codes = @user.generate_otp_backup_codes!
    @user.save!
    respond_to do |format|
      format.json { render json: { user: @user, codes: @codes } }
      format.html { render 'show' }
    end
  end

  def verify_twofa
    authorize @user
    if params[:verification_option] == 'push'
      one_touch = generate_one_touch('Request to Verify Phone Number for APTrust Repository Website')
      if one_touch.ok && (one_touch['errors'].nil? || one_touch['errors'].empty?)
        check_one_touch_verify(one_touch)
      else
        logger.info "Checking one touch contents: #{one_touch.inspect}"
        respond_to do |format|
          format.json { render json: { error: 'Create Push Error', message: one_touch.inspect }, status: :internal_server_error }
          format.html { redirect_to @user, flash: { error: "There was an error creating your push notification. Please contact your administrator or an APTrust administrator for help, and let them know that the error was: #{one_touch[:errors][:message]}" } }
        end
      end
    elsif params[:verification_option] == 'sms'
      send_sms
      redirect_to edit_verification_path(id: current_user.id, verification_type: 'phone_number')
    end
  end

  def verify_email
    authorize @user
    token = create_user_confirmation_token(@user)
    NotificationMailer.email_verification(@user, token).deliver!
    respond_to do |format|
      format.json { render json: { user: @user, message: 'Instructions on verifying email address have been sent.' } }
      format.html {
        render 'show'
        flash[:notice] = 'Instructions on verifying email address have been sent.'
      }
    end
  end

  def email_confirmation
    authorize @user
    token = ConfirmationToken.where(user_id: @user.id).first
    if token.token == params[:confirmation_token]
      @user.email_verified = true
      @user.save!
      msg = 'Your email has been successfully verified.'
      flash[:notice] = msg
    else
      ConfirmationToken.where(user_id: @user.id).delete_all
      msg = 'Invalid confirmation token.'
      flash[:error] = msg
    end
    respond_to do |format|
      format.json { render json: { user: @user, message: msg } }
      format.html { render 'show' }
    end
  end

  def generate_api_key
    authorize @user
    @user.generate_api_key
    if @user.save
      msg = ['Please record this key.  If you lose it, you will have to generate a new key.',
             "Your API secret key is: #{@user.api_secret_key}"]
      msg = msg.join('<br/>').html_safe
      flash[:notice] = msg
    else
      flash[:alert] = 'ERROR: Unable to create API key.'
    end

    redirect_to user_path(@user)
  end

  def admin_password_reset
    authorize current_user
    password = "ABCabc-#{SecureRandom.hex(4)}"
    @user.password = password
    @user.password_confirmation = password
    @user.save!
    NotificationMailer.admin_password_reset(@user, password).deliver!
    redirect_to @user
    flash[:notice] = "Password has been reset for #{@user.email}. They will be notified of their new password via email."
  end

  def deactivate
    authorize current_user
    @user.soft_delete
    (@user == current_user) ? sign_out(@user) : redirect_to(@user)
    flash[:notice] = "#{@user.name}'s account has been deactivated."
  end

  def reactivate
    authorize current_user
    @user.reactivate
    redirect_to @user
    flash[:notice] = "#{@user.name}'s account has been reactivated."
  end

  def vacuum
    authorize current_user
    if params[:vacuum_target]
      query = set_query(params[:vacuum_target])
      ActiveRecord::Base.connection.exec_query(query)
      vacuum_associated_tables(params[:vacuum_target]) if params[:vacuum_target] == 'emails' || params[:vacuum_target] == 'roles'
      respond_to do |format|
        if params[:vacuum_target] == 'entire_database'
          msg = 'The whole database'
        else
          msg = "#{params[:vacuum_target].gsub('_', ' ').capitalize.chop!} table"
        end
        format.json { render json: { status: 'success', message: "#{msg} has been vacuumed."  } }
        format.html { flash[:notice] = "#{msg} has been vacuumed." }
      end
    else
      respond_to do |format|
        format.json { }
        format.html { }
      end
    end
  end

  def account_confirmations
    authorize current_user
    User.all.each do |user|
      unless user.admin?
        update_account_attributes(user)
        token = create_user_confirmation_token(user)
        NotificationMailer.account_confirmation(user, token).deliver!
      end
    end
    respond_to do |format|
      format.json { render json: { status: 'success', message: 'All users except admins have been sent their yearly account confirmation email.' }, status: :ok }
      format.html {
        flash[:notice] = 'All users except admins have been sent their yearly account confirmation email.'
        redirect_back fallback_location: root_path
      }
    end
  end

  def indiv_confirmation_email
    authorize @user
    update_account_attributes(@user)
    token = create_user_confirmation_token(@user)
    NotificationMailer.account_confirmation(@user, token).deliver!
    respond_to do |format|
      format.json { render json: { status: 'success', message: "A new account confirmation email has been sent to this email address: #{@user.email}." }, status: :ok }
      format.html { redirect_to @user, flash: { notice: "A new account confirmation email has been sent to this email address: #{@user.email}." } }
    end
  end

  def confirm_account
    authorize @user
    token = ConfirmationToken.where(user_id: @user.id).first
    if token.token == params[:confirmation_token]
      @user.account_confirmed = true
      @user.save!
      respond_to do |format|
        format.json { render json: { user: @user, message: 'Your account has been confirmed for the next year.' } }
        format.html { redirect_to @user, flash: { notice: 'Your account has been confirmed for the next year.' } }
      end
    else
      respond_to do |format|
        format.json { render json: { user: @user, message: 'Invalid confirmation token.' } }
        format.html { redirect_to @user, flash: { error: 'Invalid confirmation token.' } }
      end
    end
  end

  private

  # If an id is passed through params, use it.  Otherwise default to show the current user.
  def set_user
    @user = params[:id].nil? ? current_user : User.readable(current_user).find(params[:id])
  end

  def build_resource_params
    [params.fetch(:user, {}).permit(:name, :email, :phone_number, :password, :password_confirmation, :institution_id, :two_factor_enabled).tap do |p|
       p[:institution_id] = build_institution_id if params[:user][:institution_id] unless params[:user].nil?
       p[:role_ids] = build_role_ids if params[:user][:role_ids] unless params[:user].nil?
     end]
  end

  def build_institution_id
    if params[:user][:institution_id].empty?
      if @user.nil?
        instituion = ''
      else
        institution = Institution.find(@user.institution_id)
      end
    else
      institution = Institution.find(params[:user][:institution_id])
    end
    unless institution.nil?
      authorize institution, :add_user?
      institution.id
    end
  end

  def build_role_ids
    [].tap do |role_ids|
      unless params[:user][:role_ids].empty?
        roles = Role.find(params[:user][:role_ids])

        authorize roles, :add_user?
        role_ids << roles.id

      end
    end
  end

  def user_params
    params.required(:user).permit(:password, :password_confirmation, :current_password, :name, :email, :phone_number, :institution_id, :role_ids, :two_factor_enabled)
  end

  def set_query(target)
    case target
      when 'checksums'
        query = 'VACUUM (VERBOSE, ANALYZE) checksums'
      when 'confirmation_tokens'
        query = 'VACUUM (VERBOSE, ANALYZE) confirmation_tokens'
      when 'dpn_bags'
        query = 'VACUUM (VERBOSE, ANALYZE) dpn_bags'
      when 'dpn_work_items'
        query = 'VACUUM (VERBOSE, ANALYZE) dpn_work_items'
      when 'emails'
        query = 'VACUUM (VERBOSE, ANALYZE) emails'
      when 'generic_files'
        query = 'VACUUM (VERBOSE, ANALYZE) generic_files'
      when 'institutions'
        query = 'VACUUM (VERBOSE, ANALYZE) institutions'
      when 'intellectual_objects'
        query = 'VACUUM (VERBOSE, ANALYZE) intellectual_objects'
      when 'premis_events'
        query = 'VACUUM (VERBOSE, ANALYZE) premis_events'
      when 'roles'
        query = 'VACUUM (VERBOSE, ANALYZE) roles'
      when 'snapshots'
        query = 'VACUUM (VERBOSE, ANALYZE) snapshots'
      when 'usage_samples'
        query = 'VACUUM (VERBOSE, ANALYZE) usage_samples'
      when 'users'
        query = 'VACUUM (VERBOSE, ANALYZE) users'
      when 'work_items'
        query = 'VACUUM (VERBOSE, ANALYZE) work_items'
      when 'work_item_states'
        query = 'VACUUM (VERBOSE, ANALYZE) work_item_states'
      when 'entire_database'
        query = 'VACUUM (VERBOSE, ANALYZE)'
    end
    query
  end

  def vacuum_associated_tables(target)
    case target
      when 'emails'
        query = 'VACUUM (VERBOSE, ANALYZE) emails_premis_events'
        ActiveRecord::Base.connection.exec_query(query)
        query = 'VACUUM (VERBOSE, ANALYZE) emails_work_items'
        ActiveRecord::Base.connection.exec_query(query)
      when 'roles'
        query = 'VACUUM (VERBOSE, ANALYZE) roles_users'
        ActiveRecord::Base.connection.exec_query(query)
    end
  end

  def one_touch_status_for_users
    @user = current_user
    status = Authy::OneTouch.approval_request_status({uuid: session[:uuid]})
    if status.ok? && (status['errors'].nil? || status['errors'].empty?)
      if session[:verify_timeout] <= 0
        msg = 'This push notification has expired'
        flash[:error] = msg
        status = :conflict
      else
        if status['approval_request']['status'] == 'approved'
          update_confirmed_two_factor_updates(@user)
          msg = 'Your phone number has been verified.'
          flash[:notice] = msg
          status = :ok
        elsif status['approval_request']['status'] == 'denied'
          msg = 'This request was denied, phone number has not been verified.'
          flash[:error] = msg
          status = :forbidden
        else
          recheck_one_touch_status_user
        end
      end
    else
      logger.info "Checking one touch contents: #{status.inspect}"
      msg = "There was a problem verifying your push notification. Please try again. If the problem persists, please contact your administrator or an APTrust administrator for help, and let them know that the error message was: #{status[:errors][:message]}."
      flash[:error] = msg
      status = :internal_server_error
    end
    respond_to do |format|
      format.json { render json: { message: msg }, status: status }
      format.html { redirect_to @user }
    end
  end
end