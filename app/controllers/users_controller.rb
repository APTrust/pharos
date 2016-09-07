class UsersController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :generate_api_key, :admin_password_reset]
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
    password = SecureRandom.hex(4)
    @user.password = password
    @user.password_confirmation = password
    @user.save!
    redirect_to @user
    flash[:notice] = "Reset password for #{@user.email}. Please notify the user that #{password} is their new password."
  end

  private

  # If an id is passed through params, use it.  Otherwise default to show the current user.
  def set_user
    @user = params[:id].nil? ? current_user : User.find(params[:id])
  end

  def build_resource_params
    [params.fetch(:user, {}).permit(:name, :email, :phone_number, :password, :password_confirmation, :institution_id).tap do |p|
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
    params.required(:user).permit(:password, :password_confirmation, :current_password, :name, :email, :phone_number, :institution_id, :role_ids)
  end
end
