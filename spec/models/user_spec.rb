# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  name                      :string
#  email                     :string
#  phone_number              :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  encrypted_password        :string           default(""), not null
#  reset_password_token      :string
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0), not null
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :string
#  last_sign_in_ip           :string
#  institution_id            :integer
#  encrypted_api_secret_key  :text
#  deactivated_at            :datetime
#  password_changed_at       :datetime
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  consumed_timestep         :integer
#  otp_required_for_login    :boolean
#  enabled_two_factor        :boolean          default(FALSE)
#  confirmed_two_factor      :boolean          default(FALSE)
#  otp_backup_codes          :string           is an Array
#  authy_id                  :string
#  last_sign_in_with_authy   :datetime
#  authy_status              :string
#  email_verified            :boolean          default(FALSE)
#  initial_password_updated  :boolean          default(FALSE)
#  force_password_update     :boolean          default(FALSE)
#  account_confirmed         :boolean          default(TRUE)
#  grace_period              :datetime
#
require 'spec_helper'
require 'devise_two_factor/spec_helpers'

describe User do
  let(:user) { FactoryBot.create(:aptrust_user) }
  let(:inst_admin) { FactoryBot.create(:user, :institutional_admin) }
  let(:inst_id) { subject.institution_id }
  let(:stale_user) { FactoryBot.create(:user, created_at: DateTime.now - 88.days) }

  before :all do
    User.delete_all
    Institution.delete_all
  end

  after :all do
    User.delete_all
    Institution.delete_all
  end

  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:name) }

  # it_behaves_like "two_factor_authenticatable"
  # it_behaves_like "two_factor_backupable"

  it 'should return a valid institution' do
    user.institution.id.should == user.institution_id
  end

  it 'should set a proper grace period' do
    time = Time.now.change(sec: 0)
    user.grace_period.change(sec: 0).should == time
  end

  describe 'as an admin' do
    subject { FactoryBot.create(:user, :admin) }
    its(:groups) { should match_array %w(registered admin) }
  end

  describe 'as an institutional admin' do
    subject { FactoryBot.create(:user, :institutional_admin) }
    its(:groups) { should match_array ['registered', 'institutional_admin', "Admin_At_#{inst_id}"]}
  end

  describe 'as an institutional user' do
    subject { FactoryBot.create(:user, :institutional_user) }
    its(:groups) { should match_array ['registered', 'institutional_user', "User_At_#{inst_id}"]}
  end

  describe '#api_secret_key=' do
    it 'encrypts the key before storing it in database' do
      key = '123'
      user.encrypted_api_secret_key.should be_nil
      stubbed_key = '456'
      user.should_receive(:password_digest).with(key).and_return(stubbed_key)

      user.api_secret_key = key
      user.encrypted_api_secret_key.should == stubbed_key
    end

    it 'sets encrypted key to nil if key is nil' do
      user.api_secret_key = '123'
      user.encrypted_api_secret_key.should_not be_nil
      user.api_secret_key = nil
      user.encrypted_api_secret_key.should be_nil
    end

    it 'sets encrypted key to nil if key is blank' do
      user.api_secret_key = '123'
      user.encrypted_api_secret_key.should_not be_nil
      user.api_secret_key = ''
      user.encrypted_api_secret_key.should be_nil
    end
  end

  describe '#api_secret_key' do
    it 'method exists' do
      user.respond_to?(:api_secret_key).should be true
    end

    it 'returns the unencrypted key if it has been set' do
      user.api_secret_key.should be_nil
      user.api_secret_key = '123'
      user.api_secret_key.should == '123'
    end
  end

  describe '#valid_api_key?' do
    it "returns false if input key doesn't match user's key" do
      user = FactoryBot.create :user, api_secret_key: '123'
      user.valid_api_key?('456').should == false
    end

    it "returns true if input key matches user's key" do
      user = FactoryBot.create :user, api_secret_key: '123'
      user.valid_api_key?('123').should == true
    end

    it "returns false if user's API key is nil" do
      user = FactoryBot.create :user
      user.encrypted_api_secret_key.should be_nil
      user.valid_api_key?(nil).should == false
    end

    it "returns false if user's API key is blank" do
      user = FactoryBot.create :user, encrypted_api_secret_key: ''
      user.encrypted_api_secret_key.should == ''
      user.valid_api_key?('').should == false
    end
  end

  describe '#generate_api_key' do
    it 'sets the encrypted_api_secret_key' do
      user.encrypted_api_secret_key.should be_nil
      user.generate_api_key
      user.encrypted_api_secret_key.should_not be_nil
    end
  end

  describe 'JSON serialization' do
    it "doesn't include the API key" do
      user.api_secret_key = '123abc123abc123abc'
      user.encrypted_api_secret_key.should_not be_nil
      user.to_json.match(/api_secret_key/).present?.should be false
    end
  end

  describe 'soft_delete' do
    it 'deactivates the user' do
      user.soft_delete
      user.deactivated_at.should_not be_nil
      user.encrypted_api_secret_key.should == ''
    end
  end

  describe 'reactivate' do
    it 'reactivates the user' do
      user.soft_delete
      user.reactivate
      user.deactivated_at.should be_nil
    end
  end

  describe 'name_or_email_like' do
    it 'filters users on partial name or email' do
      user1 = FactoryBot.create :user, name: 'user1', email: 'user1@example.com'
      user2 = FactoryBot.create :user, name: '_user2_', email: 'joe@nowhere.org'
      user3 = FactoryBot.create :user, name: 'xuser3', email: 'rails@aptrust.org'

      User.name_or_email_like('user1').count.should eq 1
      User.name_or_email_like('user1')[0].name.should eq 'user1'

      User.name_or_email_like('user2').count.should eq 1
      User.name_or_email_like('user2')[0].name.should eq '_user2_'

      org_users = User.name_or_email_like('.org')
      org_users.count.should eq 2
      org_users[0].name.should eq '_user2_'
      org_users[1].name.should eq 'xuser3'
    end
  end


  # describe 'session timeout' do
  #   it 'defaults to Devise.timeout_in' do
  #     user.timeout_in.should eq Devise.timeout_in
  #   end
  #   it 'can be reset to an integer value' do
  #     user.set_session_timeout(1234)
  #     user.timeout_in.should eq 1234
  #   end
  # end

  describe 'stale_users' do
    it 'should retrieve a list of stale users' do
      user.created_at = DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 15).days
      user.save!
      inst_admin.created_at = DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 1).days
      inst_admin.save!
      stale_user.created_at = DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 1).days
      stale_user.save!
      users = User.stale_users
      users.count.should eq 2
      users[0].should eq inst_admin
      users[1].should eq stale_user
    end
  end

end
