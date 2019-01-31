class UsersController < ApplicationController
  require 'authy'
  inherit_resources
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :generate_api_key, :admin_password_reset, :deactivate, :reactivate,
                                  :vacuum, :enable_otp, :disable_otp, :verify_twofa]
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

      authy = Authy::API.register_user(
          email: @user.email,
          cellphone: @user.phone_number,
          country_code: @user.phone_number[1]
      )
      @user.update(authy_id: authy.id)
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
      sign_in @user, :bypass => true
      redirect_to root_path
      flash[:notice] = 'Successfully changed password.'
    else
      render :edit_password
    end
  end

  def enable_otp
    authorize @user
    @user.otp_secret = User.generate_otp_secret
    @user.enabled_two_factor = true
    unless Rails.env.test?
      authy = Authy::API.register_user(
          email: @user.email,
          cellphone: @user.phone_number,
          country_code: @user.phone_number[1]
      )
      @user.update(authy_id: authy.id)
    end
    @codes = @user.generate_otp_backup_codes!
    @user.save!
    redirect_to @user
  end

  def disable_otp
    authorize @user
    @user.enabled_two_factor = false
    @user.save!
    redirect_to root_path
  end

  def verify_twofa
    authorize @user
    one_touch = Authy::OneTouch.send_approval_request(
        id: @user.authy_id,
        message: 'Request to Login to APTrust Repository Website',
        details: {
            'Email Address' => @user.email,
        }
    )
    status = one_touch['success'] ? :onetouch : :sms
    @user.update(authy_status: status)
    if @user.sms_user?
      sms = Aws::SNS::Client.new
      response = sms.publish({
                                 phone_number: @user.phone_number,
                                 message: "Your new one time password is: #{@user.current_otp}"
                             })
      redirect_to edit_verification_path(id: @user.id, verification_type: 'phone_number')
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
    redirect_to @user
    flash[:notice] = "Reset password for #{@user.email}. Please notify the user that #{password} is their new password."
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
end
